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

Given /([^ ]*) argument (.*)/ do |program, argument|
	(@programs ||= ProgramList.new)[program] << argument
end

Given /([^ ]*) is loaded/ do |program|
	(@programs ||= ProgramList.new)[program].load
end

Given /([^ ]*) is spawned/ do |program|
	(@programs ||= ProgramList.new)[program].spawn
end

Given /([^ ]*) is terminated/ do |program|
	(@programs ||= ProgramList.new)[program].terminate
end

Given /([^ ]*) will print it's output/ do |program|
	(@programs ||= ProgramList.new)[program].print_output
end

When /([^ ]*) is running/ do |program|
	(@programs ||= ProgramList.new)[program].spawn
end

When /I wait for (.*) termination/ do |program|
	(@programs ||= ProgramList.new)[program].wait_exit
	#puts (@programs ||= ProgramList.new)[program].output
end

Then /([^ ]*) exit status should be (.+)/ do |program, status|
	(@programs ||= ProgramList.new)[program].exit_status.should == status.to_i
end

After do
	@programs.terminate if @programs
end

## Common output tests

Then /([^ ]*) output should include '(.*)$'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.should include(entry)
end

Then /([^ ]*) output should not include '(.*)'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.should_not include(entry)
end

Then /([^ ]*) output should include '(.*)' (.+) time/ do |program, entry, times|
	(@programs ||= ProgramList.new)[program].output.scan(entry).size.should == times.to_i
end

Then /([^ ]*) last output line should include '(.*)'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.lines.to_a.last.should include(entry)
end

Then /([^ ]*) output should include following entries:/ do |program, log_entries|
	@program_log = (@programs ||= ProgramList.new)[program].output
	log_entries.raw.flatten.each do |entry|
		@program_log.should include(entry)
	end
end

# For debugging
Then /([^ ]*) output is displayed/ do |program|
	print (@programs ||= ProgramList.new)[program].output
end

## Common arguments

Given /([^ ]*) has debug enabled/ do |program|
	step "#{program} argument --debug"
end

Given /([^ ]*) is using linger time of (.+)/ do |program, linger_time|
	step "#{program} argument --linger-time #{linger_time}"
end

Given /([^ ]*) console connector subscribe address is (.*)/ do |program, address|
	step "#{program} argument --console-subscriber #{address}"
	# useful in other steps
	@console_connector_sub_address = address
end

Given /([^ ]*) console connector publish address is (.*)/ do |program, address|
	step "#{program} argument --console-publisher #{address}"
	# useful in other steps
	@console_connector_pub_address = address
end

