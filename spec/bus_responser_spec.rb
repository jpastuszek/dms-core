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
						poller = ZeroMQ::Poller.new
						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							BusResponder.new(bus, 'magi.sigquit.net', 'data-processor', 123)

							got_hello = false
							sub.on Hello do |msg|
								message = msg
								got_hello = true
							end

							poller << bus
							poller << sub

							begin
								pub.send Discover.new
								poller.poll(0.1)
							end until got_hello
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
				poller = ZeroMQ::Poller.new
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							BusResponder.new(bus, 'magi.sigquit.net', 'data-processor', 123)
							got_init = false
							got_end = false

							sub.on Hello, 'init' do |msg|
								got_init = true
							end

							sub.on Hello, 'end' do |msg|
								got_end = true
							end

							poller << bus
							poller << sub

							begin
								pub.send Discover.new, topic: 'init'
								poller.poll(0.1)
							end until got_init

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

							begin
								poller.poll(0.1)
							end until got_end
						end
					end
				end
			end
		end

		good.should have(3).messages
		bad.should have(0).messages
	end

	it 'should extend Bus class' do
		message = nil
		out = Capture.stderr do
			ZeroMQ.new do |zmq|
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						poller = ZeroMQ::Poller.new
						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							bus.responder('magi.sigquit.net', 'data-processor', 123)

							got_hello = false
							sub.on Hello do |msg|
								message = msg
								got_hello = true
							end

							poller << bus
							poller << sub

							begin
								pub.send Discover.new
								poller.poll(0.1)
							end until got_hello
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

end

