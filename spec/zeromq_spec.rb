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

describe ZeroMQ do
	it "should provide libzmq version" do
		ZeroMQ.lib_version.should match(/\d+\.\d+\.\d+/)
	end

	it "should provide ruby binding version version" do
		ZeroMQ.binding_version.should match(/\d+\.\d+\.\d+/)
	end

	describe "push and pull" do
		it "should allow sending and receiving RawDataPoint object" do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pull_bind('ipc:///tmp/dms-core-test') do |pull|
					zmq.push_connect('ipc:///tmp/dms-core-test') do |push|
						push.send RawDataPoint.new('magi', 'system/memory', 'cache', 123, Time.at(2.5))
					end

					message = pull.recv
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end

		it "should raise errors on bad address" do
				ZeroMQ.new do |zmq|
					expect {
						zmq.pull_bind('tcpX://127.0.0.1:2200') do |pull|
						end
					}.to raise_error ZeroMQError::OperationFailedError, "Protocol not supported"

					expect {
						zmq.push_connect('tcpX://127.0.0.1:2200') do |pull|
						end
					}.to raise_error ZeroMQError::OperationFailedError, "Protocol not supported"
				end
		end
	end
end

