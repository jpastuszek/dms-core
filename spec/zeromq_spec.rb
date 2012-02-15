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
			message.time_stamp.should == 2.5
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

