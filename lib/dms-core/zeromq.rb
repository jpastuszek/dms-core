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
		raise OperationFailedError unless ZMQ::Util.resultcode_ok?(rc)
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
			flags = 0
			flags |= ZMQ::SNDMORE if options[:more]
			ok? @socket.send_string(data_type.to_message(topic).to_s, flags)
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

			ok? @socket.setsockopt(ZMQ::HWM, options[:hwm] || 1000)
			ok? @socket.setsockopt(ZMQ::SWAP, options[:swap] || 0)
			ok? @socket.setsockopt(ZMQ::SNDBUF, options[:buffer] || 0)
		end

		def subscribe(object = '', topic = '')
			ok? @socket.setsockopt(ZMQ::SUBSCRIBE, object.empty? ? '' : "#{object}/#{topic}")
		end

		def recv(*args)
			expected_types = args
			str = ""
			ok? @socket.recv_string(str)
			message = DataType.from_message(Message.load(str))
			expected_types.any?{|et| message.is_a? et} or raise UnexpectedMessageType.new(expected_types, message) unless expected_types.empty?
			message
		end

		def more?
			@socket.more_parts?
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

		def recv
			@receiver.recv
		end

		def more?
			@receiver.more?
		end

		def recv_all
			out = []
			begin
				out << recv
			end while more?
			out
		end
	end

	class Poller
		include ZeroMQError

		def initialize
			@sockets = {}
			@poller = ZMQ::Poller.new
		end

		def register(object)
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
		end

		def poll(timeout = :blocking)
			timeout *= 1000 unless timeout == :blocking or timeout == -1
			ok? @poller.poll(timeout)
			return false if @poller.readables.empty? and @poller.writables.empty?

			yield @poller.readables.map{|socket| @sockets[socket]}, @poller.writables.map{|socket| @sockets[socket]}
			return true
		end
	end

	def initialize
		have? @context = ZMQ::Context.create(1)
		begin
			yield self
		ensure
			ok? @context.terminate
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

