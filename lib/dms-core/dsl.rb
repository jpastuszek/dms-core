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

module DSL
	class Env
	end

	def dsl_object
		@dsl_object ||= Env.new
	end

	def dsl_variable(name, default = nil)
		dsl_object.instance_eval do
			@variables ||= {}
			@variables[name] = default
		end

		dsl_object.define_singleton_method(name)do |value|
			@variables[name] = value
		end
	end

	def dsl_variables(name, default = [])
		dsl_object.instance_eval do
			@variables ||= {}
			@variables[name] = default.is_a?(Array) ? default : [default]
		end

		dsl_object.define_singleton_method(name)do |value|
			@variables[name] << value
		end
	end

	def dsl_method(name, &block) 
		dsl_object.define_singleton_method(name) do |*args|
			block.call(*args)
		end
	end

	def dsl(name = self.class.name || 'DSL', &block)
		dsl_object.define_singleton_method(:inspect) do
			name
		end

		if block
			dsl_object.instance_eval(&block)
		end

		variables = dsl_object.instance_variable_get(:@variables)
		if variables
			variables.each_pair do |name, value|
				instance_variable_set("@#{name}".to_sym, value)
			end
		end
	end
end

