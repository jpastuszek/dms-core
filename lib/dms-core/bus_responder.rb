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

class BusResponder
	def initialize(sub, pub, host_name, program, pid)
		@host_name = host_name.to_s
		@program = program.to_s

		sub.on Discover do |discover, topic|
			log.debug "received #{discover} message" 
			if host_name_match?(discover.host_name) and program_match?(discover.program)
				hello = Hello.new(host_name, program, pid)
				log.info "responding for #{discover} with #{hello} on topic: #{topic}"
				pub.send hello, topic: topic 
			end
		end
	end

	private

	def host_name_match?(host_name)
		return true if host_name == ''
		return true if host_name.is_a? Regexp and host_name =~ @host_name
		return true if host_name == @host_name
		return false
	end

	def program_match?(program)
		return true if program == ''
		return true if program == @program
		return false
	end
end

