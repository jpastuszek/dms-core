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

class BusDetector
	class NoBusError < IOError
		def initialize
			super 'no discovery response received'
		end
	end

	def initialize(program_id, bus, poller = ZeroMQ::Poller.new)
		@program_id = program_id.to_s + ':probe'
		@bus = bus
		@poller = poller
		@poller << @bus

		@ready = nil
		@bus.on Hello, @program_id do |hello|
			@ready = true
			log.debug "got: #{hello}"
		end

		@discover = Discover.new
	end
	
	def discover(time_out, delay = 0.1)
		@ready = nil
		@timeout = nil

		sending = @poller.every(delay) do
			log.debug "sending #{@discover}"
			@bus.send @discover, topic: @program_id
		end

		timeout = @poller.after(time_out) do
			log.debug "got time out (#{time_out})"
			@timeout = true
		end

		while @poller.poll
			return if ready?
			break if timeout?
		end
		raise NoBusError
	ensure
		sending.stop
		timeout.stop
	end

	def timeout?
		@timeout
	end

	def ready?
		@ready
	end
end

class Bus
	def ready!(program_id, time_out = 4.0, poller = ZeroMQ::Poller.new)
		BusDetector.new(program_id, self, poller).discover(time_out)
	end
end

