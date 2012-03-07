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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe BusDetector do
	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	it 'should broadcast Discovery messages and return on Hello response' do
		message = nil
		ZeroMQ.new do |zmq|
			zmq.sub_bind(test_address) do |sub|
				zmq.pub_connect(test_address) do |pub|
					sub.on Discover do |msg, topic|
						message = msg
						pub.send Hello.new('magi.sigquit.net', 'test', 123), topic: topic
					end

					BusDetector.new('test-program', sub, pub).discover(4)
				end
			end
		end

		message.should_not be_nil
		message.should be_a Discover
	end

	it 'should raise NoBusError on time out' do
		message = nil
		expect {
			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					zmq.pub_connect(test_address) do |pub|
						BusDetector.new('test-program', sub, pub).discover(0.1)
					end
				end
			end
		}.to raise_error BusDetector::NoBusError, 'no discovery response received'
	end
end

