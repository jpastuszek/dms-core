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
		def initialize(socket, hwm, swap, buffer, linger)
			@socket = socket
			ok? @socket.setsockopt(ZMQ::HWM, hwm)
			ok? @socket.setsockopt(ZMQ::SWAP, swap)
			ok? @socket.setsockopt(ZMQ::SNDBUF, buffer)
			ok? @socket.setsockopt(ZMQ::LINGER, (linger * 1000).to_i)
		end

		def send(data_type, topic = '')
			ok? @socket.send_string(data_type.to_message(topic).to_s)
		end
	end

	class Receiver < Socket
		def initialize(socket, hwm, swap, buffer)
			@socket = socket
			ok? @socket.setsockopt(ZMQ::HWM, hwm)
			ok? @socket.setsockopt(ZMQ::SWAP, swap)
			ok? @socket.setsockopt(ZMQ::SNDBUF, buffer)
		end

		def subscribe(object = '', topic = '')
			ok? @socket.setsockopt(ZMQ::SUBSCRIBE, object.empty? ? '' : "#{object}/#{topic}")
		end

		def recv
			str = ""
			ok? @socket.recv_string(str)
			DataType.from_message(Message.load(str))
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

	def connect_receiver(type, address, hwm, swap, buffer)
		have? socket = @context.socket(type)
		begin
			yield Receiver.new(socket, hwm, swap, buffer).connect(address)
		ensure
			ok? socket.close
		end
	end

	def bind_receiver(type, address, hwm, swap, buffer)
		have? socket = @context.socket(type)
		begin
			yield Receiver.new(socket, hwm, swap, buffer).bind(address)
		ensure
			ok? socket.close
		end
	end

	def connect_sender(type, address, hwm, swap, buffer, linger)
		have? socket = @context.socket(type)
		begin
			yield Sender.new(socket, hwm, swap, buffer, linger).connect(address)
		ensure
			ok? socket.close
		end
	end

	def bind_sender(type, address, hwm, swap, buffer, linger)
		have? socket = @context.socket(type)
		begin
			yield Sender.new(socket, hwm, swap, buffer, linger).bind(address)
		ensure
			ok? socket.close
		end
	end

	# PUSH/PULL
	def pull_bind(address, hwm = 1000, swap = 0, buffer = 0, &block)
		bind_receiver(ZMQ::PULL, address, hwm, swap, buffer, &block)
	end

	def push_connect(address, hwm = 1000, swap = 0, buffer = 0, linger = 10, &block)
		connect_sender(ZMQ::PUSH, address, hwm, swap, buffer, linger, &block)
	end

	# PUB/SUB
	def pub_bind(address, hwm = 1000, swap = 0, buffer = 0, linger = 10, &block)
		bind_sender(ZMQ::PUB, address, hwm, swap, buffer, linger, &block)
	end

	def pub_connect(address, hwm = 1000, swap = 0, buffer = 0, linger = 10, &block)
		connect_sender(ZMQ::PUB, address, hwm, swap, buffer, linger, &block)
	end

	def sub_bind(address, hwm = 1000, swap = 0, buffer = 0, &block)
		bind_receiver(ZMQ::SUB, address, hwm, swap, buffer, &block)
	end

	def sub_connect(address, hwm = 1000, swap = 0, buffer = 0, &block)
		connect_receiver(ZMQ::SUB, address, hwm, swap, buffer, &block)
	end
end

