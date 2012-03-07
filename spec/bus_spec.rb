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

describe Bus do
	let :subscriber_address do
		'ipc:///tmp/dms-core-test-sub'
	end

	let :publisher_address do
		'ipc:///tmp/dms-core-test-pub'
	end

	context 'connect' do
		it 'should allow sending objects' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						sub.on Hello, 'test' do |msg|
							message = msg
						end

						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							bus.poll_for(sub)
							begin
								bus.send Hello.new('abc', 'xyz', 123), topic: 'test'
								bus.poll(0.1)
							end until message
						end
					end
				end
			end

			message.host_name.should == 'abc'
		end

		it 'should allow receiving objects' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_bind(subscriber_address) do |sub|
					zmq.pub_bind(publisher_address) do |pub|
						Bus.connect(zmq, publisher_address, subscriber_address) do |bus|
							bus.on Hello, 'test' do |msg|
								message = msg
							end

							bus.poll_for(sub)
							begin
								pub.send Hello.new('abc', 'xyz', 123), topic: 'test'
								bus.poll(0.1)
							end until message
						end
					end
				end
			end

			message.host_name.should == 'abc'
		end
	end

	context 'bind' do
		it 'should allow sending objects' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_connect(publisher_address) do |sub|
					zmq.pub_connect(subscriber_address) do |pub|
						sub.on Hello, 'test' do |msg|
							message = msg
						end

						Bus.bind(zmq, publisher_address, subscriber_address) do |bus|
							bus.poll_for(sub)
							begin
								bus.send Hello.new('abc', 'xyz', 123), topic: 'test'
								bus.poll(0.1)
							end until message
						end
					end
				end
			end

			message.host_name.should == 'abc'
		end

		it 'should allow receiving objects' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_connect(publisher_address) do |sub|
					zmq.pub_connect(subscriber_address) do |pub|
						Bus.bind(zmq, publisher_address, subscriber_address) do |bus|
							bus.on Hello, 'test' do |msg|
								message = msg
							end

							bus.poll_for(sub)
							begin
								pub.send Hello.new('abc', 'xyz', 123), topic: 'test'
								bus.poll(0.1)
							end until message
						end
					end
				end
			end

			message.host_name.should == 'abc'
		end
	end
end

