# Copyright (c) 2012 Jakub Pastuszek
#
# This file is part of Distributed Monitoring System.
#
# Distributed Monitoring System is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Distributed Monitoring System is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Distributed Monitoring System.  If not, see <http://www.gnu.org/licenses/>.

require 'ffi-rzmq'
require 'ffi-rzmq/version'
require 'set'
require 'periodic-scheduler'
require_relative 'message_callback_register'

module ZeroMQError
	class OperationFailedError < IOError
		def initialize
			if ZMQ::Util.errno == 0
				super "Unknown ZeroMQ error (errno 0)"
			else
				super "#{ZMQ::Util.error_string}"
			end
		end
	end

	def have?(rc)
		raise OperationFailedError unless rc
		rc
	end

	def ok?(rc)
		have?(rc)
		unless ZMQ::Util.resultcode_ok?(rc)
			raise Interrupt if ZMQ::Util.errno == Errno::EINTR::Errno
			raise OperationFailedError 
		end
		rc
	end
end

class ZeroMQ
	include ZeroMQError

	def self.lib_version
		lib = ZMQ::LibZMQ::version
		"#{lib[:major]}.#{lib[:minor]}.#{lib[:patch]}"
	end

	def self.binding_version
		ZMQ::VERSION
	end

	class Socket
		include ZeroMQError
		
		class NilAddressGivenError < ArgumentError
			def initialize
				super "socket address cannot be nil"
			end
		end

		def initialize(socket)
			@socket = socket
			@on_close = []
			begin
				yield socket
			rescue
				close
				raise
			ensure
				close unless @close_at_exit
			end
		end

		attr_reader :socket

		def connect(address)
			raise NilAddressGivenError unless address
			ok? @socket.connect(address)
			self
		end

		def bind(address)
			raise NilAddressGivenError unless address
			ok? @socket.bind(address)
			self
		end

		def close_at_exit
			at_exit do
				close
			end
			@close_at_exit = true
		end

		def close
			return if closed?
			# call only once
			@closed = true
			
			# call callbacks before socket gets closed/unusable
			@on_close.shift.call(self) until @on_close.empty?

			ok? @socket.close
		end

		def on_close(&callback)
			@on_close << callback
		end

		def closed?
			@closed
		end
	end

	module Sender
		def sender_init(options)
			ok? @socket.setsockopt(ZMQ::HWM, options[:hwm] || 1000)
			ok? @socket.setsockopt(ZMQ::SWAP, options[:swap] || 0)
			ok? @socket.setsockopt(ZMQ::SNDBUF, options[:buffer] || 0)
			ok? @socket.setsockopt(ZMQ::LINGER, ((options[:linger] || 10) * 1000).to_i)
		end

		def send(data, options = {})
			data = data.to_message(options[:topic]) if data.is_a? DataType

			flags = 0
			flags |= ZMQ::SNDMORE if options[:more]
			ok? @socket.send_string(data.to_s, flags)
			self
		end
	end

	module Receiver
		def receiver_init(options)
			@message_callback_register = MessageCallbackRegister.new

			ok? @socket.setsockopt(ZMQ::HWM, options[:hwm] || 1000)
			ok? @socket.setsockopt(ZMQ::SWAP, options[:swap] || 0)
			ok? @socket.setsockopt(ZMQ::SNDBUF, options[:buffer] || 0)
		end

		def on(data_type, topic = nil, &callback)
			@message_callback_register.on(data_type, topic, &callback)
		end

		def receive!
			begin
				@message_callback_register << recv_raw 
			end while more?
			self
		end

		private

		def recv_raw
			string = ""
			ok? @socket.recv_string(string)
			string
		end

		def more?
			@socket.more_parts?
		end
	end

	class Publisher < Socket
		include Sender
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::PUB)
			super socket do
				sender_init(options)
				yield self
			end
		end
	end

	class Pusher < Socket
		include Sender
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::PUSH)
			super socket do
				sender_init(options)
				yield self
			end
		end
	end

	class Subscriber < Socket
		include Receiver
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::SUB)
			super socket do
				receiver_init(options)
				yield self
			end
		end

		def on(data_type, topic = nil, &callback)
			callback = super
			subscribe(data_type.is_a?(Symbol) ? nil : data_type, topic)
			callback.on_close do
				unsubscribe(data_type.is_a?(Symbol) ? nil : data_type, topic)
			end
			callback
		end

		private

		# Subscription strings:
		# '' - for all
		# 'DataType/' - for given object, all topics
		# 'DataType/topic\n' - given object, given topic
		def subscribe(data_type = nil, topic = nil)
			topic_string = data_type ? "#{data_type}/#{topic ? topic + "\n" : ''}" : ''
			#puts "sub: #{topic_string}"
			ok? @socket.setsockopt(ZMQ::SUBSCRIBE, topic_string)
			self
		end

		def unsubscribe(data_type = nil, topic = nil)
			topic_string = data_type ? "#{data_type}/#{topic ? topic + "\n" : ''}" : ''
			#puts "unsub: #{topic_string}"
			ok? @socket.setsockopt(ZMQ::UNSUBSCRIBE, topic_string)
			self
		end
	end

	class Puller < Socket
		include Receiver
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::PULL)
			super socket do
				receiver_init(options)
				yield self
			end
		end
	end

	class Reply < Socket
		include Receiver
		include Sender
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::REP)
			super socket do
				sender_init(options)
				receiver_init(options)
				yield self
			end
		end
	end

	class Request < Socket
		include Receiver
		include Sender
		def initialize(context, options = {})
			have? socket = context.socket(ZMQ::REQ)
			super socket do
				sender_init(options)
				receiver_init(options)
				@response_callback = nil
				on(:any) do |message|
					@response_callback.call(message) if @response_callback
				end
				yield self
			end
		end

		def send(data_type, options = {}, &callback)
			@response_callback = callback
			super data_type, options
			self
		end

		def receive!
			super
			@response_callback = nil
			self
		end
	end

	class Poller
		include ZeroMQError

		def initialize
			@sockets = {}
			@poller = ZMQ::Poller.new
			@scheduler = PeriodicScheduler.new(0.001, wait_function: method(:poll_message))
		end

		def <<(object)
			@poller.register_readable(object.socket)
			@sockets[object.socket] = object
		end

		def deregister(object)
			@poller.deregister_readable(object.socket) unless object.closed?
			@sockets.delete(object)
		end

		def after(time, &callback)
			@scheduler.after(time) do
				callback.call
				nil
			end
		end

		def every(time, &callback)
			@scheduler.every(time) do
				callback.call
				nil
			end
		end

		def poll(timeout = nil)
			timeout = @scheduler.after(timeout){:timeout} if timeout

			# nothing scheduled, wait for message
			if @scheduler.empty?
				poll_message
				return :message
			end

			objects = @scheduler.run do |error|
				log.error "poller timer event raised error", error
			end

			# cancel running time out
			timeout.stop if timeout

			if objects.empty?
				# poll_message returned quickly - got message
				return :message
			elsif objects.include? :timeout
				return false
			else
				return :timer
			end
		end

		def poll!(time = nil)
			if time
				done = false
				after(time) do
					done = true
				end

				poll until done
			else
				loop do
					poll
				end
			end
		end

		private

		def poll_message(timeout = nil)
			if timeout
				# poller returns immediately if empty
				if @poller.size == 0
					sleep timeout
					return false
				end 

				timeout *= 1000 if timeout
				ok? @poller.poll(timeout)
				return false if @poller.readables.empty? and @poller.writables.empty?
			else
				ok? @poller.poll(:blocking)
			end

			@poller.readables.each do |socket|
				@sockets[socket].receive!
			end
			return true
		end
	end

	def initialize
		have? @context = ZMQ::Context.create(1)
		if block_given?
			begin
				yield self
			ensure
				terminate
			end
		else
			at_exit do
				terminate
			end
		end
	end

	def terminate
		begin
			ok? @context.terminate
		rescue Interrupt
			retry
		rescue
		end
	end

	# all type_connect/bind method combinations
	[:pull, :push, :rep, :req, :pub, :sub].zip(
		[Puller, Pusher, Reply, Request, Publisher, Subscriber]
	).product([:bind, :connect]).each do |type, bind|
		eval """
		def #{type.first}_#{bind}(address, options = {})
			#{type.last}.new(@context, options) do |socket|
				socket.#{bind}(address)
				if block_given?
					yield socket
				else
					socket.close_at_exit
				end
			end
		end
		"""
	end
end

