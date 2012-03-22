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

Given /(.+) program$/ do |program|
	@program = program
	@program_args = []
end

Given /debug enabled/ do
	@program_args << ['--debug']
end

Given /use linger time of (.+)/ do |linger_time|
	@program_args << ['--linger-time', linger_time.to_i]
end

Given /console connector subscribe address is (.*)/ do |address|
	@program_args << ['--console-subscriber', address]
	@console_connector_sub_address = address
end

Given /console connector publish address is (.*)/ do |address|
	@program_args << ['--console-publisher', address]
	@console_connector_pub_address = address
end

When /it is started$/ do
	@program_args = @program_args.join(' ')

	puts "#{@program} #{@program_args}"
	@program_process = RunProgram.new(@program, @program_args)#{|line| puts line}
end

Then /terminate the process/ do
	@program_process.terminate
end

Then /log output should include following entries:/ do |log_entries|
	@program_log = @program_process.output
	log_entries.raw.flatten.each do |entry|
		@program_log.should include(entry)
	end
end

