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
	let :test_address2 do
		'ipc:///tmp/dms-core-test2'
	end

	let :test_raw_data_point do
		RawDataPoint.new('magi', 'system/memory', 'cache', 123, Time.at(2.5))
	end

	let :test_raw_data_point2 do
		RawDataPoint.new('magi', 'system/CPU usage', 'user', 123, Time.at(2.5))
	end

	it "should provide libzmq version" do
		ZeroMQ.lib_version.should match(/\d+\.\d+\.\d+/)
	end

	it "should provide ruby binding version version" do
		ZeroMQ.binding_version.should match(/\d+\.\d+\.\d+/)
	end

	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	describe "PUSH and PULL" do
		it 'should allow sending and receiving raw string messages' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.pull_bind(test_address) do |pull|
					zmq.push_connect(test_address) do |push|
						push.send_raw 'hello world'
					end

					pull.on_raw do |msg|
						message = msg
					end.receive!
				end
			end
			message.should == 'hello world'
		end

		it 'should allow sending multiple objects' do
			ZeroMQ.new do |zmq|
				zmq.pull_bind(test_address) do |pull|
					zmq.push_connect(test_address) do |push|
						push.send test_raw_data_point, more: true
						push.send test_raw_data_point2
					end

					messages = []
					pull.on RawDataPoint do |raw_data_point|
						messages << raw_data_point
					end.receive!

					messages.should have(2).messages

					message = messages.shift
					message.should be_a RawDataPoint
					message.path.should == 'system/memory'

					message = messages.shift
					message.should be_a RawDataPoint
					message.path.should == 'system/CPU usage'
				end
			end
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

		it 'should support polling' do
			messages = []

			ZeroMQ.new do |zmq|
				zmq.pull_bind(test_address) do |pull1|
					zmq.pull_bind(test_address2) do |pull2|
						poller = ZeroMQ::Poller.new

						zmq.push_connect(test_address) do |push1|
							push1.send test_raw_data_point
						end
						zmq.push_connect(test_address2) do |push2|
							push2.send test_raw_data_point2, topic: 'test'
						end

						pull1.on(RawDataPoint) do |raw_data_point|
							messages << raw_data_point
						end
						poller << pull1

						pull2.on(RawDataPoint) do |raw_data_point, topic|
							messages << raw_data_point
							topic.should == 'test'
						end
						poller << pull2

						begin
							poller.poll(4)
						end while messages.length < 2
					end
				end
			end

			messages.should have(2).messages

			message = messages.shift
			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123

			message = messages.shift
			message.should be_a RawDataPoint
			message.path.should == 'system/CPU usage'
			message.component.should == 'user'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end
	end

	describe 'PUB and SUB' do
		it 'should allow sending and receiving raw string messages' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					zmq.pub_connect(test_address) do |pub|
						thread = Thread.new do
							loop do
								pub.send_raw 'hello world'
								sleep 0.1
							end
						end

						sub.on_raw do |msg|
							message = msg
						end.receive!

						thread.kill
					end
				end
			end

			message.should == 'hello world'
		end

		it 'should allow sending and receinving objects' do
			message = nil
			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					zmq.pub_connect(test_address) do |pub|
						thread = Thread.new do
							pub.send test_raw_data_point
							sleep 0.1
						end

						sub.on RawDataPoint do |raw_data_point|
							message = raw_data_point
						end.receive!

						thread.kill
					end
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end

		it 'should allow sending and receinving objects - reverse bind/connect' do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pub_bind(test_address) do |pub|
					zmq.sub_connect(test_address) do |sub|
						thread = Thread.new do
							loop do
								pub.send test_raw_data_point
								sleep 0.1
							end
						end

						sub.on RawDataPoint do |raw_data_point|
							message = raw_data_point
						end.receive!

						thread.kill
					end
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end

		it 'should allow sending and receinving RawDataPoint object - with topic' do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.on RawDataPoint, 'hello world' do |msg, topic|
						message = msg
						topic.should == 'hello world'
					end

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point, topic: 'hello world'
					end

					sub.receive!
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.on RawDataPoint, 'hello' do |msg, topic|
						message = msg
						topic = 'hello'
					end

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point2, topic: 'hello world'
						pub.send test_raw_data_point, topic: 'hello'
					end

					sub.receive!
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end

		it 'should pass topic messages to on handler with same topic' do
			cpu_topic_messages = []
			memory_topic_messages = []
			all_messages = []

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.on RawDataPoint, 'memory' do |message, topic|
						memory_topic_messages << message
					end

					sub.on RawDataPoint, 'cpu' do |message, topic|
						cpu_topic_messages << message
					end

					sub.on RawDataPoint, '' do |message, topic|
						all_messages << message
					end

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point, topic: 'memory'
						pub.send test_raw_data_point2, topic: 'cpu'
					end

					sub.receive!
					sub.receive!
				end
			end

			cpu_topic_messages.should have(1).message
			cpu_topic_messages.shift.path.should == 'system/CPU usage'

			memory_topic_messages.should have(1).message
			memory_topic_messages.shift.path.should == 'system/memory'

			all_messages.should have(2).message
			all_messages.shift.path.should == 'system/memory'
			all_messages.shift.path.should == 'system/CPU usage'
		end

		it 'should support polling with topic' do
			messages = []

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub1|
					zmq.sub_bind(test_address2) do |sub2|
						poller = ZeroMQ::Poller.new

						zmq.pub_connect(test_address) do |pub|
							pub.send test_raw_data_point
						end

						zmq.pub_connect(test_address2) do |pub|
							pub.send test_raw_data_point2, topic: 'test'
						end

						sub1.on RawDataPoint do |raw_data_point|
							messages << raw_data_point
						end
						poller << sub1

						sub2.on RawDataPoint, 'test' do |raw_data_point, topic|
							messages << raw_data_point
							topic.should == 'test'
						end
						poller << sub2

						begin
							poller.poll(4)
						end while messages.length < 2
					end
				end
			end

			messages.should have(2).messages

			message = messages.shift
			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123

			message = messages.shift
			message.should be_a RawDataPoint
			message.path.should == 'system/CPU usage'
			message.component.should == 'user'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end
	end

	describe 'REQ and REP' do
		it 'should allow sending requests and receinving response objects' do
			messages = []

			ZeroMQ.new do |zmq|
				zmq.rep_bind(test_address) do |rep|
					rep.on Discover do |discover|
						rep.send Hello.new(discover.host_name, 'abc', 123)
					end

					zmq.req_connect(test_address) do |req|
						req.send Discover.new('abc') do |response|
							messages << response
						end

						rep.receive!
						req.receive!
					end
				end
			end

			messages.should have(1).messages

			message = messages.shift
			message.host_name.should == 'abc'
			message.program.should == 'abc'
			message.pid.should == 123
		end

		it 'should support polling' do
			messages = []

			ZeroMQ.new do |zmq|
				poller = ZeroMQ::Poller.new

				zmq.rep_bind(test_address) do |rep|
					rep.on Discover do |discover|
						rep.send Hello.new(discover.host_name, 'abc', 123)
					end

					poller << rep

					zmq.rep_bind(test_address2) do |rep|
						rep.on Discover do |discover|
							rep.send Hello.new(discover.host_name, 'xyz', 321), topic: 'test'
						end

						poller << rep

						zmq.req_connect(test_address) do |req|
							req.send Discover.new('abc') do |response|
								messages << response
							end

							poller << req

							zmq.req_connect(test_address2) do |req|
								req.send Discover.new('xyz') do |response|
									messages << response
								end

								poller << req

								begin
									poller.poll(4)
								end while messages.length < 2
							end
						end
					end
				end
			end

			messages.should have(2).messages

			message = messages.shift
			message.host_name.should == 'abc'
			message.program.should == 'abc'
			message.pid.should == 123

			message = messages.shift
			message.host_name.should == 'xyz'
			message.program.should == 'xyz'
			message.pid.should == 321
		end
	end
end

