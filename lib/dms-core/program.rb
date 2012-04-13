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
require 'facter'

class Program
	class Tool < Program
		def initialize(*args)
			super
			MainTool.new(@settings.program_class_name, @settings, &@main) if @main
		end
	end

	class Daemon < Program
		def initialize(*args)
			super
			MainDaemon.new(@settings.program_class_name, @settings, &@main) if @main
		end
	end

	class MainTool
		def initialize(class_name, settings, &block)
			@settings = settings
			Logging.logger.root.appenders = Logging.appenders.stderr(:layout => Logging::Layouts.pattern(pattern: "%d - %m\n"))
			Logging.logger.root.level = :debug if @settings.debug 
			logging_class_name class_name

			log.debug "#{@settings.program_name} version #{@settings.version} (LibZMQ version #{@settings.libzmq_version}, ffi-ruby version #{@settings.libzmq_binding_version}); pid #{@settings.pid}"

			instance_exec @settings, &block
		rescue Interrupt, SystemExit
		rescue Exception => error
			log.fatal 'got error', error
			exit 2
		end
	end

	class MainDaemon
		def initialize(class_name, settings, &block)
			@settings = settings
			Logging.logger.root.level = :debug if @settings.debug 
			logging_class_name class_name

			log.info "Starting #{@settings.program_name} version #{@settings.version} (LibZMQ version #{@settings.libzmq_version}, ffi-ruby version #{@settings.libzmq_binding_version}); pid #{@settings.pid}"

			instance_exec @settings, &block
		rescue SystemExit
			raise
		rescue Exception => error
			log.fatal 'got error', error
			exit 2
		ensure
			log.info "#{@settings.program_name} done"
		end

		def main_loop(&block)
			log.info "#{@settings.program_name} ready"
			block.call
		rescue Interrupt
			log.info 'interrupted'
		rescue => error
			log.fatal 'got error', error
			exit 3
		ensure
			log.info 'shutting down...'
		end
	end

	include DSL

	def initialize(program_name, version, argv = ARGV, &block)
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

				define_singleton_method(:internal_console_connection) do
					option :internal_console_subscriber,
						short: :i, 
						description: 'ZeroMQ adderss of console connector for console programs - subscriber', 
						default: 'ipc:///tmp/dms-console-connector-sub'
					option :internal_console_publisher,
						short: :I, 
						description: 'ZeroMQ adderss of console connector for console programs - publisher', 
						default: 'ipc:///tmp/dms-console-connector-pub'
				end

				define_singleton_method(:linger_time) do
					option :linger_time,
						short: :L,
						cast: Integer,
						description: 'seconds to wait for outstanding messages to be sent out before exiting',
						default: 10
				end

				define_singleton_method(:hello_wait) do
					option :hello_wait,
						short: :w,
						cast: Float,
						description: 'wait given number of seconds for Hello message',
						default: 4
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
		@validator ||= lambda{|s| }
		@main  ||= lambda{|s| }

		@cli.version version
		
		@cli.switch :debug,
				short: :d,
				description: 'enable debugging'

		@settings = @cli.parse!(argv, &@validator)

		@settings.program_name = program_name
		@settings.program_class_name = @settings.program_name.delete(' ')
		@settings.program = program_name.downcase.tr ' ', '-'
		@settings.pid = Process.pid
		@settings.host_name = Facter.fqdn
		@settings.program_id = "#{@settings.program}:#{@settings.host_name}:#{@settings.pid}"
		@settings.version = version
		@settings.libzmq_version = ZeroMQ.lib_version
		@settings.libzmq_binding_version = ZeroMQ.binding_version
	end
end

