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

	def initialize(program_id, bus)
		@program_id = program_id.to_s + ':probe'
		@bus = bus

		@ready = nil
		@bus.on Hello, @program_id do |hello|
			@ready = true
			log.debug "got: #{hello}"
		end
		@discover = Discover.new
	end
	
	def discover(time_out, delay = 0.1)
		@ready = nil
		end_time = Time.now + time_out.to_f
		next_discover = Time.now
		loop do
			if next_discover <= Time.now
				log.debug "sending #{@discover}"
				@bus.send @discover, topic: @program_id
				next_discover += delay
			end
			break if @bus.poll(delay) and ready?
			raise NoBusError if end_time <= Time.now
		end
	end

	def ready?
		@ready
	end
end


