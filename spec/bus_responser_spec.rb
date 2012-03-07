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

describe BusResponder do
	let :subscriber_address do
		'ipc:///tmp/dms-core-test-sub'
	end

	let :publisher_address do
		'ipc:///tmp/dms-core-test-pub'
	end

	it 'should respond to broadcas Discover message' do
		message = nil
		out = Capture.stderr do
			ZeroMQ.new do |zmq|
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							BusResponder.new(bus, 'magi.sigquit.net', 'data-processor', 123)

							sub.on Hello do |msg|
								message = msg
							end

							thread = Thread.new do
								loop do
									pub.send Discover.new
									sleep 0.1
								end
							end

							bus.poll(4)
							sub.receive!
							thread.kill
						end
					end
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

		out = Capture.stderr do
			ZeroMQ.new do |zmq|
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						Bus.connect(zmq, publisher_address, subscriber_address, linger: 0) do |bus|
							BusResponder.new(bus, 'magi.sigquit.net', 'data-processor', 123)
							bus_poller = Thread.new do
								bus.poll!(4)
							end

							got_init = nil
							got_end = nil

							sub.on Hello, 'init' do |msg|
								got_init = true
							end

							sub.on Hello, 'end' do |msg|
								got_end = true
							end

							thread = Thread.new do
								loop do
									pub.send Discover.new, topic: 'init'
									sleep 0.1
								end
							end

							until got_init
								sub.receive!
							end
							thread.kill

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

							bus_poller.kill
						end
					end
				end
			end
		end

		good.should have(3).messages
		bad.should have(0).messages
	end
end

