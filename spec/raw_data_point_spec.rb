require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RawDataPoint do
	subject do
		RawDataPoint.new('magi', 'Memory usage', 'RAM', 'cache', Time.at(1), 123)
	end

	it "takes type, group, component and value" do
		subject.location.should == 'magi'
		subject.type.should == 'Memory usage'
		subject.group.should == 'RAM'
		subject.component.should == 'cache'
		subject.time_stamp.should == 1
		subject.value.should == 123
	end

	it "can be converted to Message" do
		m = subject.to_message

		m.data_type.should == 'RawDataPoint'
		m.topic.should == ''
		m[:location].should == 'magi'
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:time_stamp].should == 1
		m[:value].should == 123
	end

	it "can be converted to Message - with topic" do
		m = subject.to_message('Topic')

		m.data_type.should == 'RawDataPoint'
		m.topic.should == 'Topic'
		m[:location].should == 'magi'
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:time_stamp].should == 1
		m[:value].should == 123
	end

	it "can be created from Message" do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a RawDataPoint
		dt.location.should == 'magi'
		dt.type.should == 'Memory usage'
		dt.group.should == 'RAM'
		dt.component.should == 'cache'
		dt.time_stamp.should == 1
		dt.value.should == 123
	end
end

