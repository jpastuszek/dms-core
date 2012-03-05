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

require 'dms-core/data_type'

class Hello < DataType
	attr_reader :host_name
	attr_reader :program
	attr_reader :pid

	def initialize(host_name, program, pid)
		@host_name = host_name.to_s
		@program = program.to_s
		@pid = pid.to_i
	end

	def self.from_message(message)
		self.new(
			message[:host_name],
			message[:program], 
			message[:pid], 
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:host_name] = @host_name
			body[:program] = @program
			body[:pid] = @pid
		end
	end

	def to_s
		"Hello[#{@host_name}/#{@program}:#{@pid}]"
	end

	register(self)
end


