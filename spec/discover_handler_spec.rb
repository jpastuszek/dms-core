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

describe DiscoverHandler do
	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	it 'should respond to broadcas Discover message' do
		message = nil
		ZeroMQ.new do |zmq|
			zmq.sub_bind(test_address) do |sub|
				zmq.pub_connect(test_address) do |pub|
					DiscoverHandler.new(sub, pub, 'magi.sigquit.net', 'data-processor', 123)

					sub.on Hello do |msg|
						message = msg
					end

					pub.send Discover.new
					sub.receive!
					sub.receive!
				end
			end
		end

		message.should_not be_nil
		message.host_name.should == 'magi.sigquit.net'
		message.program.should == 'data-processor'
		message.pid.should == 123
	end

	it 'should respond to broadcas Discover message that match host_name and program strings' do
		good = []
		bad = []

		ZeroMQ.new do |zmq|
			zmq.sub_bind(test_address) do |sub|
				zmq.pub_connect(test_address) do |pub|
					DiscoverHandler.new(sub, pub, 'magi.sigquit.net', 'data-processor', 123)

					got_init = nil
					got_end = nil

					sub.on Hello, 'init' do |msg|
						got_init = true
					end

					sub.on Hello, 'end' do |msg|
						got_end = true
					end

					pub.send Discover.new, topic: 'init'
					until got_init
						sub.receive!
					end

					sub.on Hello,'good' do |msg, topic|
						good << msg
					end

					sub.on Hello,'bad' do |msg, topic|
						bad << msg
					end

					pub.send Discover.new('/.*/', ''), topic: 'good'
					pub.send Discover.new('bogous', ''), topic: 'bad'
					pub.send Discover.new('/bogous/', ''), topic: 'bad'
					pub.send Discover.new('/.*/', 'data-processor'), topic: 'good'
					pub.send Discover.new('', 'bogous'), topic: 'bad'
					pub.send Discover.new('', 'data-processor'), topic: 'good'

					pub.send Discover.new, topic: 'end'
					until got_end
						sub.receive!
					end
				end
			end
		end

		good.should have(3).messages
		bad.should have(0).messages
	end
end

