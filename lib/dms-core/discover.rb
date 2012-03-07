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

class Discover < DataType
	attr_reader :host_name
	attr_reader :program

	def initialize(host_name = '', program = '')
		@host_name = host_name.to_s
		if @host_name[0] == '/' and @host_name[-1] == '/'
			@host_name = Regexp.new(@host_name.slice(1...-1), Regexp::EXTENDED | Regexp::IGNORECASE)
		end

		@program = program.to_s
	end

	def self.from_message(message)
		self.new(
			message[:host_name],
			message[:program], 
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:host_name] = @host_name.is_a?(Regexp) ? @host_name.inspect.scan(/\/.*\//).first : @host_name
			body[:program] = @program
		end
	end

	def to_s
		"Discover[#{@host_name.is_a?(Regexp) ? @host_name.inspect.scan(/\/.*\//).first : @host_name}/#{@program}]"
	end

	register(self)
end

