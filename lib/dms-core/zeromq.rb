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
		def initialize(socket, options = {})
			@socket = socket

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
		class UnexpectedMessageType < IOError
			def initialize(expected, message)
				super "received message of type: #{message.class.name}, expected #{expected.join(' or ')}"
			end
		end

		def initialize(socket, options = {})
			@socket = socket
			@data_type_callbacks = {}

			ok? @socket.setsockopt(ZMQ::HWM, options[:hwm] || 1000)
			ok? @socket.setsockopt(ZMQ::SWAP, options[:swap] || 0)
			ok? @socket.setsockopt(ZMQ::SNDBUF, options[:buffer] || 0)
		end

		def subscribe(object = nil, topic = '')
			ok? @socket.setsockopt(ZMQ::SUBSCRIBE, ! object ? '' : "#{object}/#{topic.empty? ? '' : topic + "\n"}")
		end

		def recv(*expected_types)
			message = DataType.from_message(Message.load(recv_raw))
			expected_types.any?{|et| message.is_a? et} or raise UnexpectedMessageType.new(expected_types, message) unless expected_types.empty?
			message
		end

		def recv_with_topic
			message = Message.load(recv_raw)
			[DataType.from_message(message), message.topic]
		end

		def recv_raw
			string = ""
			ok? @socket.recv_string(string)
			string
		end

		def more?
			@socket.more_parts?
		end

		def recv_all(*expected_types)
			out = []
			begin
				out << recv(*expected_types)
			end while more?
			out
		end

		def on(data_type, &callback)
			@data_type_callbacks[data_type] = callback
		end

		def receive!
			begin
				message, topic = recv_with_topic
				if callback = @data_type_callbacks[message.class]
					callback.call(message, topic)
				end
			end while more?
		end
	end

	class SenderReceiver < Socket
		def initialize(socket, options = {})
			@socket = socket
			@sender = Sender.new(socket, options)
			@receiver = Receiver.new(socket, options)
		end

		def send(data_type, options = {})
			@sender.send(data_type, options)
		end

		def send_raw(string, options)
			@sender.send_raw(string, options)
		end

		def recv(*expected_types)
			@receiver.recv(*expected_types)
		end

		def recv_raw
			@receiver.recv_raw
		end

		def more?
			@receiver.more?
		end

		def recv_all(*expected_types)
			@receiver.recv_all(*expected_types)
		end
	end

	class Poller
		include ZeroMQError

		def initialize
			@sockets = {}
			@callbacks = {}
			@poller = ZMQ::Poller.new
		end

		def on(object, &callback)
			case object
			when Sender
				@poller.register_writable(object.socket)
			when Receiver
				@poller.register_readable(object.socket)
			when SenderReceiver
				@poller.register(object.socket)
			else
				raise TypeError, 'expected Sender, Receiver or SenderReceiver type of object'
			end

			@sockets[object.socket] = object
			@callbacks[object.socket] = callback
		end

		def on_message(receiver, data_type, &callback)
			receiver.on(data_type, &callback)
			on(receiver) do
				receiver.receive!
			end
		end

		def poll(timeout = :blocking)
			timeout *= 1000 unless timeout == :blocking or timeout == -1
			ok? @poller.poll(timeout)
			return false if @poller.readables.empty? and @poller.writables.empty?

			(@poller.writables + @poller.readables).each do |socket|
				@callbacks[socket].call(@sockets[socket])
			end
		end

		def poll!
			loop{poll}
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

	def connect_receiver(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield Receiver.new(socket, options).connect(address)
		ensure
			ok? socket.close
		end
	end

	def bind_receiver(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield Receiver.new(socket, options).bind(address)
		ensure
			ok? socket.close
		end
	end

	def connect_sender(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield Sender.new(socket, options).connect(address)
		ensure
			ok? socket.close
		end
	end

	def bind_sender(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield Sender.new(socket, options).bind(address)
		ensure
			ok? socket.close
		end
	end

	def connect_sender_receiver(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield SenderReceiver.new(socket, options).connect(address)
		ensure
			ok? socket.close
		end
	end

	def bind_sender_receiver(type, address, options = {})
		have? socket = @context.socket(type)
		begin
			yield SenderReceiver.new(socket, options).bind(address)
		ensure
			ok? socket.close
		end
	end

	# PUSH/PULL
	def pull_bind(address, options = {}, &block)
		bind_receiver(ZMQ::PULL, address, options, &block)
	end

	def push_connect(address, options = {}, &block)
		connect_sender(ZMQ::PUSH, address, options, &block)
	end

	# REQ/REP
	def rep_bind(address, options = {}, &block)
		bind_sender_receiver(ZMQ::REP, address, options, &block)
	end

	def req_connect(address, options = {}, &block)
		connect_sender_receiver(ZMQ::REQ, address, options, &block)
	end

	# PUB/SUB
	def pub_bind(address, options = {}, &block)
		bind_sender(ZMQ::PUB, address, options, &block)
	end

	def pub_connect(address, options = {}, &block)
		connect_sender(ZMQ::PUB, address, options, &block)
	end

	def sub_bind(address, options = {}, &block)
		bind_receiver(ZMQ::SUB, address, options, &block)
	end

	def sub_connect(address, options = {}, &block)
		connect_receiver(ZMQ::SUB, address, options, &block)
	end
end

