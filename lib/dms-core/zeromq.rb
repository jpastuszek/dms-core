require 'ffi-rzmq'

module ZeroMQErrors
	class OperationFailedError < IOError
		def initialize
			 super "Errno #{ZMQ::Util.errno}: #{ZMQ::Util.error_string}"
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
	include ZeroMQErrors

	class Sender
		include ZeroMQErrors

		def initialize(socket)
			@socket = socket
		end

		def send(data_type)
			ok? @socket.send_string(data_type.to_message.to_s)
		end
	end

	class Receiver
		include ZeroMQErrors

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

	def pull_bind(address)
		have? socket = @context.socket(ZMQ::PULL)
		begin
			ok? socket.bind(address)
			yield Receiver.new(socket)
		ensure
			ok? socket.close
		end
	end

	def push_connect(address)
		have? socket = @context.socket(ZMQ::PUSH)
		begin
			ok? socket.connect(address)
			yield Sender.new(socket)
		ensure
			ok? socket.close
		end
	end
end

