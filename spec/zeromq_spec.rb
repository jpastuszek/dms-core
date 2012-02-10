require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ZeroMQ do
	describe "push and pull" do
		it "should allow sending and receiving RawDatum object" do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pull_bind('ipc:///tmp/dms-core-test') do |pull|
					zmq.push_connect('ipc:///tmp/dms-core-test') do |push|
						push.send RawDatum.new('Memory usage', 'RAM', 'cache', 123, Time.at(2.5))
					end

					message = pull.recv
				end
			end

			message.should be_a RawDatum
			message.type.should == 'Memory usage'
			message.group.should == 'RAM'
			message.component.should == 'cache'
			message.time_stamp.should == 2.5
			message.value.should == 123
		end

		it "should raise errors on bad address" do
				ZeroMQ.new do |zmq|
					expect {
						zmq.pull_bind('tcpX://127.0.0.1:2200') do |pull|
						end
					}.to raise_error ZeroMQError::OperationFailedError, "Errno 93: Protocol not supported"

					expect {
						zmq.push_connect('tcpX://127.0.0.1:2200') do |pull|
						end
					}.to raise_error ZeroMQError::OperationFailedError, "Errno 93: Protocol not supported"
				end
		end
	end
end

