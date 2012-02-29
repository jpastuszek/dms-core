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

	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	let :test_raw_data_point do
		RawDataPoint.new('magi', 'system/memory', 'cache', 123, Time.at(2.5))
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
	end

	describe 'PUB and SUB' do
		it 'should allow sending and receinving RawDataPoint object' do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.sub_bind(test_address) do |sub|
					sub.subscribe('RawDataPoint')

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
						sub.subscribe('RawDataPoint')

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
					sub.subscribe('RawDataPoint', 'hello world')

					zmq.pub_connect(test_address) do |pub|
						pub.send test_raw_data_point, 'hello world'
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
	end

	describe 'REQ and REP' do
		it 'should allow sending DataSetQuery and receinving DataSet object' do
			ZeroMQ.new do |zmq|
				zmq.rep_bind(test_address) do |rep|
					zmq.req_connect(test_address) do |req|
						req.send DataSetQuery.new('abc123', 'location:/magi\./, system:memory', Time.at(100), Time.at(0), 1)

						message = rep.recv
						message.should be_a DataSetQuery
						message.query_id.should == 'abc123'
						message.tag_expression.to_s.should == 'location:/magi\./, system:memory'
						message.time_from.should == Time.at(100).utc
						message.time_to.should == Time.at(0).utc
						message.granularity.should == 1.0

						rep.send(DataSet.new('memory', 'location:magi, system:memory', 'B', Time.at(100), Time.at(0)) do
							component_data 'free', 1, 1234
							component_data 'free', 2, 1235
							component_data 'used', 1, 3452
							component_data 'used', 2, 3451
						end)

						message = req.recv
						message.tag_set.should be_match('location:magi')
						message.tag_set.should be_match('system:memory')
						message.time_from.should be_utc
						message.time_to.should be_utc
						message.component_data.should be_a(Hash)
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

