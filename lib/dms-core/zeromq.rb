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
	end

	class Sender < Socket
		class Publisher < Sender
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::PUB)
				begin
					super socket, options
					yield self
				ensure
					ok? socket.close
				end
			end
		end

		class Pusher < Sender
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::PUSH)
				begin
					super socket, options
					yield self
				ensure
					ok? socket.close
				end
			end
		end

		def initialize(socket, options = {})
			super socket

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
		end
	end

	class Receiver < Socket
		class Subscriber < Receiver
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::SUB)
				begin
					super socket, options

					@on_handlers = {}
					yield self
				ensure
					ok? socket.close
				end
			end

			def on(data_type, topic = '', &callback)
				unless @on_handlers.has_key? data_type
					@on_handlers[data_type] = {}

					super data_type do |message, topic|
						on_topic = @on_handlers[data_type]
						if topic != '' and on_topic.has_key? topic
							on_topic[topic].call(message, topic)
						end

						if on_topic.has_key? ''
							on_topic[''].call(message, topic)
						end
					end
				end

				on_topic = @on_handlers[data_type]
				subscribe(data_type, topic) unless on_topic.has_key? topic
				on_topic[topic] = callback

				self
			end

			def on_raw(&callback)
				subscribe
				super &callback
			end

			private

			def subscribe(object = nil, topic = '')
				ok? @socket.setsockopt(ZMQ::SUBSCRIBE, ! object ? '' : "#{object}/#{topic.empty? ? '' : topic + "\n"}")
			end
		end

		class Puller < Receiver
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::PULL)
				begin
					super socket, options
					yield self
				ensure
					ok? socket.close
				end
			end
		end

		def initialize(socket, options = {})
			super socket
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

	class SenderReceiver < Socket
		class Reply < SenderReceiver
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::REP)
				begin
					super socket, options
					yield self
				ensure
					ok? socket.close
				end
			end

			def on(data_type, &callback)
				@receiver.on(data_type, &callback)
			end

			def receive!
				@receiver.receive!
			end
		end

		class Request < SenderReceiver
			def initialize(context, options = {})
				have? socket = context.socket(ZMQ::REQ)
				begin
					super socket, options

					@response_callback = nil

					@receiver.on_other do |message|
						@response_callback.call(message) if @response_callback
					end

					yield self
				ensure
					ok? socket.close
				end
			end

			def send(data_type, options = {}, &callback)
				@response_callback = callback
				super data_type, options
			end

			def receive!
				@receiver.receive!
				@response_callback = nil
			end
		end

		def initialize(socket, options = {})
			super socket
			@sender = Sender.new(socket, options)
			@receiver = Receiver.new(socket, options)
		end

		def send(data_type, options = {}, &callback)
			@sender.send(data_type, options)
			self
		end
	end

	class Poller
		include ZeroMQError

		def initialize
			@sockets = {}
			@poller = ZMQ::Poller.new
		end

		def <<(object)
			@poller.register_readable(object.socket)
			@sockets[object.socket] = object
		end

		def poll(timeout = :blocking)
			timeout *= 1000 unless timeout == :blocking or timeout == -1
			ok? @poller.poll(timeout)
			return false if @poller.readables.empty? and @poller.writables.empty?

			@poller.readables.each do |socket|
				@sockets[socket].receive!
			end
			return true
		end

		def poll!(time = nil)
			if time
				end_time = Time.now + time
				handled_messages = false
				loop do
					time_remaining = end_time - Time.now
					return handled_messages if time_remaining <= 0
					poll(time_remaining)
					handled_messages = true
				end
			else
				loop{poll}
			end
		end
	end

	def initialize
		have? @context = ZMQ::Context.create(1)
		begin
			yield self
		ensure
			begin
				ok? @context.terminate
			rescue Interrupt
				retry
			rescue
			end
		end
	end

	# PUSH/PULL
	def pull_bind(address, options = {}, &block)
		Receiver::Puller.new(@context, options) do |pull|
			pull.bind(address)
			yield pull
		end
	end

	def push_connect(address, options = {}, &block)
		Sender::Pusher.new(@context, options) do |push|
			push.connect(address)
			yield push
		end
	end

	# REQ/REP
	def rep_bind(address, options = {}, &block)
		SenderReceiver::Reply.new(@context, options) do |rep|
			rep.bind(address)
			yield rep
		end
	end

	def req_connect(address, options = {}, &block)
		SenderReceiver::Request.new(@context, options) do |req|
			req.connect(address)
			yield req
		end
	end

	# PUB/SUB
	def pub_bind(address, options = {}, &block)
		Sender::Publisher.new(@context, options) do |pub|
			pub.bind(address)
			yield pub
		end
	end

	def pub_connect(address, options = {}, &block)
		Sender::Publisher.new(@context, options) do |pub|
			pub.connect(address)
			yield pub
		end
	end

	def sub_bind(address, options = {})
		Receiver::Subscriber.new(@context, options) do |sub|
			sub.bind(address)
			yield sub
		end
	end

	def sub_connect(address, options = {}, &block)
		Receiver::Subscriber.new(@context, options) do |sub|
			sub.connect(address)
			yield sub
		end
	end
end

