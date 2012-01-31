require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ZeroMQ do
	describe "push and pull" do
		it "should allow sending and receiving RawDatum object" do
			message = nil

			ZeroMQ.new do |zmq|
				zmq.pull_bind('tcp://127.0.0.1:2200') do |pull|
					zmq.push_connect('tcp://127.0.0.1:2200') do |push|
						push.send RawDatum.new('Memory usage', 'RAM', 'cache', 123)
					end

					message = pull.recv
				end
			end

			message.should be_a RawDatum
			message.type.should == 'Memory usage'
			message.group.should == 'RAM'
			message.component.should == 'cache'
			message.value.should == 123
		end
	end
end

