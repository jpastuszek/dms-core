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

require 'shellwords'
require 'pathname'
require 'daemon'

class ProgramList
	class Program
		class NotStartedError < RuntimeError
			def initialize(name)
				super "program #{name} was not started"
			end
		end

		def initialize(name)
			@name = name
			@args = []
		end

		def spawn
			terminate
			@program = SpawnProgram.new("bin/#{@name}", Shellwords.join(@args))
		end

		def load
			terminate
			@program = LoadProgram.new("bin/#{@name}", Shellwords.join(@args))
		end

		def <<(arg)
			@args.concat Shellwords.split(arg)
		end

		def terminate
			@program.terminate if @program
		end

		def method_missing(name, *args)
			raise NotStartedError.new(name) unless @program
			@program.send(name, *args)
		end
	end

	def initialize
		@programs = {}
		@program_args = {}
	end

	def [](name)
		@programs[name] ||= Program.new(name)
	end

	def terminate
		@programs.each do |name, program|
			program.terminate
		end
	end
end

class ProgramBase
	def terminate(pid)
		#puts ">> terminating #{pid}"
		Process.kill('INT', pid)

		80.times do
			#print '.'
			Process.waitpid(pid, Process::WNOHANG)
			sleep 0.1
		end

		puts "killing #{pid}..."
		Process.kill('KILL', pid)
		Process.waitpid(pid)
		puts "killed #{pid}"
	rescue Errno::ESRCH # nothing to kill
		#puts "<- #{pid} already gone"
	rescue Errno::ECHILD # child is gone (terminated)
		#puts "<< #{pid} terminated"
		@exit_status = $?.exitstatus
	end

	def wait_exit(pid)
		Process.waitpid(pid)
		@exit_status = $?.exitstatus
	end

	attr_reader :exit_status

	def wait_url(test_url)
		Timeout.timeout(10) do
			begin
				HTTPClient.new.get_content(URI.encode(test_url))
			rescue Errno::ECONNREFUSED
				sleep 0.1
				retry
			end
		end
	end
end

class SpawnProgram < ProgramBase
	def initialize(program, args = '')
		#puts ">> spawning #{program} #{args}"
		r, w = IO.pipe
		@pid = Process.spawn("bundle exec #{program} #{args}", :out => w, :err => w)
		w.close
		@out_queue = Queue.new

		@thread = Thread.new do
			r.each_line do |line|
				yield line if block_given?
				#puts line
				@out_queue << line
			end
		end

		@out = []

		at_exit do
			terminate
		end
		#puts "<< spawned #{program}: pid: #{@pid}"
	end

	def output
		@out << @out_queue.pop until @out_queue.empty?
		@out.join
	end

	def terminate
		super @pid
	ensure
		@thread.join
		self
	end

	def wait_exit
		super @pid
	end
end

class LoadProgram < ProgramBase
	def initialize(program, args = '')
		program = Pathname.new(program)
		@pid_file = Pathname.new('/tmp') + program.basename.sub_ext('.pid')
		@log_file = Pathname.new('/tmp') + program.basename.sub_ext('.log')

		fork do
			@log_file.exist? and @log_file.truncate(0)
			Daemon.daemonize(@pid_file, @log_file)

			ENV['ARGS'] = args
			load program
		end

		Process.wait

		at_exit do
			terminate
		end
	end

	def pid
		pid_file = Pathname.new(@pid_file)
		return nil unless pid_file.exist?

		pid_file.read.strip.to_i
	end

	def output
		@log_file.read
	end

	def terminate
		super(pid || return)
	end

	def wait_exit
		super pid
	end
end

