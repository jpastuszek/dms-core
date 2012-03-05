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

	it 'should allow sending and receiving raw string messages' do
		ZeroMQ.new do |zmq|
			zmq.pull_bind(test_address) do |pull|
				zmq.push_connect(test_address) do |push|
					push.send_raw 'hello world'
				end

				pull.recv_raw.should == 'hello world'
			end
		end
	end

	describe 'sending' do
		it '#send should allow sending multiple objects' do
			ZeroMQ.new do |zmq|
				zmq.pull_bind(test_address) do |pull|
					zmq.push_connect(test_address) do |push|
						push.send test_raw_data_point, more: true
						push.send test_raw_data_point2
					end

					message = pull.recv
					message.should be_a RawDataPoint
					message.path.should == 'system/memory'

					pull.more?.should be_true
					
					message = pull.recv
					message.should be_a RawDataPoint
					message.path.should == 'system/CPU usage'

					pull.more?.should be_false
				end
			end
		end
	end

	describe 'receiving' do
		describe '#recv' do
			it "should allow specifing accepted classes" do
				message = nil

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point
						end

						expect {
							pull.recv(RawDataPoint)
						}.to_not raise_error
					end
				end

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point
						end

						expect {
							pull.recv(DataSetQuery, RawDataPoint)
						}.to_not raise_error
					end
				end

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point
						end

						expect {
							pull.recv(DataSetQuery)
						}.to raise_error ZeroMQ::Receiver::UnexpectedMessageType, 'received message of type: RawDataPoint, expected DataSetQuery'
					end
				end

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point
						end

						expect {
							pull.recv(DataSetQuery, DataSet)
						}.to raise_error ZeroMQ::Receiver::UnexpectedMessageType, 'received message of type: RawDataPoint, expected DataSetQuery or DataSet'
					end
				end
			end
		end

		describe '#recv_all' do
			it 'should return all messages in array' do
				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point, more: true
							push.send test_raw_data_point2
						end

						messages = pull.recv_all
						messages.should have(2).raw_data_points

						message = messages.shift
						message.should be_a RawDataPoint
						message.path.should == 'system/memory'
						
						message = messages.shift
						message.should be_a RawDataPoint
						message.path.should == 'system/CPU usage'
					end
				end
			end

			it 'should allow specifing accepted classes' do
				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point, more: true
							push.send test_raw_data_point2
						end

						expect {
							pull.recv_all(RawDataPoint)
						}.to_not raise_error
					end
				end

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point, more: true
							push.send test_raw_data_point2
						end

						expect {
							pull.recv_all(DataSet, RawDataPoint)
						}.to_not raise_error
					end
				end

				ZeroMQ.new do |zmq|
					zmq.pull_bind(test_address) do |pull|
						zmq.push_connect(test_address) do |push|
							push.send test_raw_data_point, more: true
							push.send test_raw_data_point2
						end

						expect {
							pull.recv_all(DataSetQuery)
						}.to raise_error ZeroMQ::Receiver::UnexpectedMessageType, 'received message of type: RawDataPoint, expected DataSetQuery'
					end
				end
			end
		end
	end

	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	describe "PUSH and PULL" do
		it "should allow sending and receiving RawDataPoint object" do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pull_bind(test_address) do |pull|
					zmq.push_connect(test_address) do |push|
						push.send test_raw_data_point
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
		it 'should allow sending and receinving RawDataPoint object' do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.subscribe(RawDataPoint)

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point
					end

					message = sub.recv
				end
			end

			message.should be_a RawDataPoint
			message.path.should == 'system/memory'
			message.component.should == 'cache'
			message.time_stamp.should == Time.at(2.5).utc
			message.value.should == 123
		end

		it 'should allow sending and receinving RawDataPoint object - reverse bind/connect' do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pub_bind(test_address) do |pub|
					zmq.sub_connect(test_address) do |sub|
						sub.subscribe(RawDataPoint)

						keep_trying do
							pub.send test_raw_data_point
							message = sub.recv
						end
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
					sub.on RawDataPoint, 'hello world' do |message, topic|
						message.should be_a RawDataPoint
						message.path.should == 'system/memory'
						message.component.should == 'cache'
						message.time_stamp.should == Time.at(2.5).utc
						message.value.should == 123

						topic.should == 'hello world'
					end

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point, topic: 'hello world'
					end

					sub.receive!
				end
			end

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.on RawDataPoint, 'hello' do |message, topic|
						message.should be_a RawDataPoint
						message.path.should == 'system/memory'
						message.component.should == 'cache'
						message.time_stamp.should == Time.at(2.5).utc
						message.value.should == 123

						topic = 'hello'
					end

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point2, topic: 'hello world'
						pub.send test_raw_data_point, topic: 'hello'
					end

					sub.receive!
				end
			end
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
		it 'should allow sending DataSetQuery and receinving DataSet object' do
			ZeroMQ.new do |zmq|
				zmq.rep_bind(test_address) do |rep|
					zmq.req_connect(test_address) do |req|
						req.send DataSetQuery.new('location:/magi\./, system:memory', Time.at(100), 100, 1)

						message = rep.recv
						message.should be_a DataSetQuery
						message.tag_expression.to_s.should == 'location:/magi\./, system:memory'
						message.time_from.should == Time.at(100).utc
						message.time_span.should == 100.0
						message.granularity.should == 1.0

						rep.send(DataSet.new('memory', 'location:magi, system:memory', Time.at(100), 100) do
							component_data 'free', 1, 1234
							component_data 'free', 2, 1235
							component_data 'used', 1, 3452
							component_data 'used', 2, 3451
						end)

						message = req.recv
						message.tag_set.should be_match('location:magi')
						message.tag_set.should be_match('system:memory')
						message.time_from.should be_utc
						message.time_span.should be_a Float
						message.component_data.should be_a Hash
						message.component_data.should have_key('used')
						message.component_data['used'][0][0].should == Time.at(1).utc
						message.component_data['used'][0][1].should == 3452
						message.component_data.should have_key('free')
					end
				end
			end
		end
	end
end

