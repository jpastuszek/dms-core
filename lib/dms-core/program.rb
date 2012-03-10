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

require 'dms-core'
require 'cli'

class Program
	class Tool < Program
	end

	class Daemon < Program
	end

	class Main
		def initialize(class_name, settings, &block)
			logging_class_name class_name
			instance_exec settings, &block
		end
	end

	include DSL

	def initialize(program_name, version, argv = ARGV, &block)
		@cli = nil
		@validator = lambda{|s| }
		@main = nil

		dsl_method :cli do |&block|
			@cli = CLI.new do
				define_singleton_method(:console_connection) do
					option :console_subscriber,
						short: :c, 
						description: 'ZeroMQ adderss of console connector - subscriber', 
						default: 'tcp://127.0.0.1:12000'
					option :console_publisher,
						short: :C, 
						description: 'ZeroMQ adderss of console connector - publisher', 
						default: 'tcp://127.0.0.1:12001'
				end

				instance_eval &block
			end
		end

		dsl_method :validate do |&block|
			@validator = block
		end

		dsl_method :main do |&block|
			@main = block
		end

		dsl &block

		@cli ||= CLI.new

		@cli.version version
		
		@cli.switch :debug,
				short: :d,
				description: 'enable debugging'

		settings = @cli.parse!(argv, &@validator)

		settings.program_name = program_name
		settings.version = version
		settings.libzmq_version = ZeroMQ.lib_version
		settings.libzmq_binding_version = ZeroMQ.binding_version
		settings.pid = Process.pid

		Logging.logger.root.level = :debug if settings.debug

		class_name = program_name.delete ' '
		logging_class_name class_name
		log.info "Starting #{settings.program_name} version #{settings.version} (LibZMQ version #{settings.libzmq_version}, ffi-ruby version #{settings.libzmq_binding_version}); pid #{settings.pid}"

		Main.new(class_name, settings, &@main) if @main
	end
end

