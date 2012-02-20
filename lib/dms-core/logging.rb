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

require 'logging'

Logging.logger.root.appenders = Logging.appenders.stderr(:layout => Logging::Layouts::Pattern.new)
Logging.logger.root.level = :info

module Kernel
	def log
		class_name = @logging_class_name ? @logging_class_name : self.class.name.split("::").last

		if @logging_context
			class_name += '[' + @logging_context.to_s + ']'
		end

		Logging.logger[class_name]
	end

	def logging_class_name(string)
		@logging_class_name = string
	end

	def logging_context(string)
		@logging_context = string
	end
end

