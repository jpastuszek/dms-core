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

Given /ZeroMQ service bus is configured with console connector publisher address (.*) and subscriber address (.*)/ do |pub, sub|
	ZeroMQService.socket(:bus) do |zmq|
		zmq.bus_connect(pub, sub, {hwm: 10, linger: 0})
	end unless ZeroMQService.socket(:bus)
end

Then /I expect (.*) ZeroMQ bus messages/ do |messages|
	messages.to_i.times do
		ZeroMQService.socket(:bus).receive!
	end
end

