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

Given /(.*) program argument (.*)/ do |program, argument|
	(@programs ||= ProgramList.new)[program] << argument
end

Given /(.*) program is loaded/ do |program|
	(@programs ||= ProgramList.new)[program].load
end

Given /(.*) program is spawned/ do |program|
	(@programs ||= ProgramList.new)[program].spawn
end

Given /(.*) program is terminated/ do |program|
	(@programs ||= ProgramList.new)[program].terminate
end

When /I wait for (.*) program termination/ do |program|
	(@programs ||= ProgramList.new)[program].wait_exit
end

Then /(.*) program exit status should be (.+)/ do |program, status|
	(@programs ||= ProgramList.new)[program].exit_status.should == status.to_i
end

## Common output tests

Then /(.*) program output should include '(.*)$'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.should include(entry)
end

Then /(.*) program output should not include '(.*)'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.should_not include(entry)
end

Then /(.*) program output should include '(.*)' (.+) time/ do |program, entry, times|
	(@programs ||= ProgramList.new)[program].output.scan(entry).size.should == times.to_i
end

Then /(.*) program last output line should include '(.*)'/ do |program, entry|
	(@programs ||= ProgramList.new)[program].output.lines.to_a.last.should include(entry)
end

Then /(.*) program output should include following entries:/ do |program, log_entries|
	@program_log = (@programs ||= ProgramList.new)[program].output
	log_entries.raw.flatten.each do |entry|
		@program_log.should include(entry)
	end
end

## Common arguments

Given /(.*) program debug enabled/ do |program|
	step "#{program} program argument --debug"
end

Given /(.*) program use linger time of (.+)/ do |program, linger_time|
	step "#{program} program argument --linger-time #{linger_time}"
end

Given /(.*) program console connector subscribe address is (.*)/ do |program, address|
	step "#{program} program argument --console-subscriber #{address}"
end

Given /(.*) program console connector publish address is (.*)/ do |program, address|
	step "#{program} program argument --console-publish #{address}"
end

