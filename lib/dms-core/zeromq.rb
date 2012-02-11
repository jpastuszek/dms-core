require 'ffi-rzmq'
require 'ffi-rzmq/version'

module ZeroMQError
	class OperationFailedError < IOError
		def initialize
			if ZMQ::Util.errno == 0
				super "Unknown ZeroMQ error (errno 0)"
			else
				super "Errno #{ZMQ::Util.errno}: #{ZMQ::Util.error_string}"
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

	class Sender
		include ZeroMQError

		def initialize(socket)
			@socket = socket
		end

		def send(data_type)
			ok? @socket.send_string(data_type.to_message.to_s)
		end
	end

	class Receiver
		include ZeroMQError

		def initialize(socket)
			@socket = socket
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

	def pull_bind(address, hwm = 1000, swap = 0, buffer = 0)
		have? socket = @context.socket(ZMQ::PULL)
		ok? socket.setsockopt(ZMQ::HWM, hwm)
		ok? socket.setsockopt(ZMQ::SWAP, swap)
		ok? socket.setsockopt(ZMQ::SNDBUF, buffer)
		begin
			ok? socket.bind(address)
			yield Receiver.new(socket)
		ensure
			ok? socket.close
		end
	end

	def push_connect(address, hwm = 1000, swap = 0, buffer = 0, linger = 10)
		have? socket = @context.socket(ZMQ::PUSH)
		ok? socket.setsockopt(ZMQ::HWM, hwm)
		ok? socket.setsockopt(ZMQ::SWAP, swap)
		ok? socket.setsockopt(ZMQ::SNDBUF, buffer)
		ok? socket.setsockopt(ZMQ::LINGER, (linger * 1000).to_i)
		begin
			ok? socket.connect(address)
			yield Sender.new(socket)
		ensure
			ok? socket.close
		end
	end
end

