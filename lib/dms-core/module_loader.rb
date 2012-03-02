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

require 'pathname'

class ModuleBase
	include DSL

	def initialize(name, &block)
		@name = name
		dsl &block
	end

	attr_reader :name

	def self.load(name, string)
		self.new(name) do
			eval string
		end
	end
end

class ModuleLoader
	def initialize(module_class)
		@module_class = module_class
	end

	def load_directory(module_dir)
		module_dir = Pathname.new(module_dir.to_s)
		
		module_dir.children.select{|f| f.extname == '.rb'}.sort.inject([]) do |modules, module_file|
			m = load_file(module_file)
			modules << m if m
		end
	end

	def load_file(module_file)
		module_file = Pathname.new(module_file.to_s)

		module_name = module_file.basename(module_file.extname).to_s
		log.info "loading module '#{module_name}' from: #{module_file}"
		begin
			return @module_class.load(module_name, module_file.read)
		rescue => error
			log.error "error while loading module '#{module_name}'", error
			return nil
		end
	end
end

