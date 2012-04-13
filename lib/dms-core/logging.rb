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

# monkey patch to support exception and object logging
class Logging::Logger
	class << self
		def define_log_methods( logger )
			::Logging::LEVELS.each do |name,num|
				code = "undef :#{name} if method_defined? :#{name}\n"
				code << "undef :#{name}? if method_defined? :#{name}?\n"

				if logger.level > num
					code << <<-CODE
						def #{name}?( ) false end
						def #{name}( data = nil, *objects ) false end
CODE
				else
					code << <<-CODE
						def #{name}?( ) true end
						def #{name}( data = nil, *objects )
							unless objects.empty?
								data << ': '
								data << objects.map do |obj|
									if obj.is_a? Exception
										"\#{obj.class.name}: \#{obj.message}\n\#{obj.backtrace.join("\n")}"
									else
										obj.to_s
									end
								end.join(', ')
							end
							data = yield if block_given?
							log_event(::Logging::LogEvent.new(@name, #{num}, data, @trace))
							true
						end
CODE
				end

				logger._meta_eval(code, __FILE__, __LINE__)
			end
			logger
		end
	end
end

Logging.logger.root.level = :info

module Kernel
	def log
		class_name = @logging_class_name ? @logging_class_name : self.class.name ? self.class.name.split("::").last : 'Main'

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

