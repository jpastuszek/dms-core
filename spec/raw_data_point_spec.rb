require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RawDataPoint do
	subject do
		RawDataPoint.new('magi', 'system/memory', 'cache', 123, Time.at(2.35))
	end

	it "takes type, path, component and value" do
		subject.location.should == 'magi'
		subject.path.should == 'system/memory'
		subject.component.should == 'cache'
		subject.value.should == 123
		subject.time_stamp.should == 2.35
	end

	it "can be converted to Message" do
		m = subject.to_message

		m.data_type.should == 'RawDataPoint'
		m.topic.should == ''
		m[:location].should == 'magi'
		m[:path].should == 'system/memory'
		m[:component].should == 'cache'
		m[:value].should == 123
		m[:time_stamp].should == 2.35
	end

	it "can be converted to Message - with topic" do
		m = subject.to_message('Topic')

		m.data_type.should == 'RawDataPoint'
		m.topic.should == 'Topic'
		m[:location].should == 'magi'
		m[:path].should == 'system/memory'
		m[:component].should == 'cache'
		m[:value].should == 123
		m[:time_stamp].should == 2.35
	end

	it "can be created from Message" do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a RawDataPoint
		dt.location.should == 'magi'
		dt.path.should == 'system/memory'
		dt.component.should == 'cache'
		dt.value.should == 123
		dt.time_stamp.should == 2.35
	end
end

