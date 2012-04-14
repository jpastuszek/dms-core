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

class ZeroMQServiceInstance
	class SocketExistsError < ArgumentError
		def initialize(name)
			super "socket #{name} already exists"
		end
	end

	def initialize
		@zeromq = nil
		@sockets = {}
	end

	def zeromq
		@zeromq ||= ZeroMQ.new
	end

	def poller
		@poller ||= ZeroMQ::Poller.new
	end

	def socket(name, &block)
		if socket = @sockets[name] and socket.closed?
			poller.deregister(socket)
			@sockets.delete name 
		end

		if block_given?
			raise SocketExistsError, name if @sockets.member? name
			socket = yield zeromq
			@sockets[name] = socket
			poller << socket
		end
		@sockets[name]
	end
end

ZeroMQService ||= ZeroMQServiceInstance.new

