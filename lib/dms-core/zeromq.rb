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

		def initialize(socket)
			@socket = socket
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
			ok? @socket.connect(address)
			self
		end

		def bind(address)
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
			ok? @socket.close unless @closed
			@closed = true
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

		def send(data_type, options = {})
			topic = options[:topic] || nil
			send_raw(data_type.to_message(topic).to_s, options)
		end

		def send_raw(string, options = {})
			flags = 0
			flags |= ZMQ::SNDMORE if options[:more]
			ok? @socket.send_string(string, flags)
			self
		end
	end

	module Receiver
		def receiver_init(options)
			@data_type_callbacks = {}
			@raw_callbacks = []
			@othre_callbacks = []

			ok? @socket.setsockopt(ZMQ::HWM, options[:hwm] || 1000)
			ok? @socket.setsockopt(ZMQ::SWAP, options[:swap] || 0)
			ok? @socket.setsockopt(ZMQ::SNDBUF, options[:buffer] || 0)
		end

		def on_raw(&callback)
			@raw_callbacks << callback
			self
		end

		def on(data_type, &callback)
			(@data_type_callbacks[data_type] ||= []) << callback
			self
		end

		def on_other(&callback)
			@othre_callbacks << callback
			self
		end

		def receive!
			begin
				raw_message = recv_raw
				@raw_callbacks.each do |callback|
					callback.call(raw_message)
				end

				unless @data_type_callbacks.empty? and @othre_callbacks.empty?
					message = Message.load(raw_message)
					data_type = DataType.from_message(message)

					if callbacks = @data_type_callbacks[data_type.class]
						callbacks.each do |callback|
							callback.call(data_type, message.topic)
						end
					else
						@othre_callbacks.each do |callback|
							callback.call(data_type, message.topic)
						end
					end
				end
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
				@on_handlers = {}
				yield self
			end
		end

		def on(data_type, topic = '', &callback)
			unless @on_handlers.has_key? data_type
				@on_handlers[data_type] = {}

				# set callback on data_type
				super data_type do |message, topic|
					# find topic handler if any
					on_topic = @on_handlers[data_type]
					if topic != '' and on_topic.has_key? topic
						on_topic[topic].call(message, topic)
					end

					# call on all topic handler
					if on_topic.has_key? ''
						on_topic[''].call(message, topic)
					end
				end
			end

			on_topic = @on_handlers[data_type]
			subscribe(data_type, topic) unless on_topic.has_key? topic
			# this allows only one data_type/topic pair callback to be set
			on_topic[topic] = callback
			self
		end

		def on_raw(&callback)
			subscribe
			super &callback
		end

		private

		# Subscription strings:
		# '' - for all
		# 'DataType/' - for given object, all topics
		# 'DataType/topic\n' - given object, given topic
		def subscribe(data_type = nil, topic = '')
			ok? @socket.setsockopt(ZMQ::SUBSCRIBE, ! data_type ? '' : "#{data_type}/#{topic.empty? ? '' : topic + "\n"}")
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
				on_other do |message|
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

		class Timers < SortedSet
			class Timer
				def initialize(at, &callback)
					@at = at
					@callback = callback
				end

				attr_reader :at

				def remaining
					@at - Time.now
				end

				def call
					@callback.call
				end

				def <=>(x)
					@at <=> x.at
				end
			end

			def after(time, &callback)
				self << Timer.new(Time.now + time, &callback)
			end

			def wait
				loop do
					while timer = first and timer.remaining <= 0
						timer.call
						delete(timer)
						return true
					end
					return false if empty?

					# sleep
					yield first.remaining
				end
			end
		end

		def initialize
			@sockets = {}
			@poller = ZMQ::Poller.new
			@timers = Timers.new
		end

		def <<(object)
			@poller.register_readable(object.socket)
			@sockets[object.socket] = object
		end

		def deregister(object)
			@poller.deregister_readable(object.socket)
			@sockets.delete(object)
		end

		def after(time, &callback)
			@timers.after(time, &callback)
		end

		def poll(timeout = nil)
			@timers.wait do |time_remaining|
				break if timeout and timeout < time_remaining
				poll_message(time_remaining) and return :message
			end and return :timer

			if poll_message(timeout)
				return :message
			else
				return false
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
			timeout *= 1000 if timeout
			ok? @poller.poll(timeout || :blocking)
			return false if @poller.readables.empty? and @poller.writables.empty?

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

