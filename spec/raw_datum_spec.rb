require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RawDatum do
	subject do
		RawDatum.new('Memory usage', 'RAM', 'cache', 123)
	end

	it "takes type, group, component and value" do
		subject.type.should == 'Memory usage'
		subject.group.should == 'RAM'
		subject.component.should == 'cache'
		subject.value.should == 123
	end

	it "can be converted to Message" do
		m = subject.to_message

		m.data_type.should == 'RawDatum'
		m.topic.should == ''
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:value].should == 123
	end

	it "can be converted to Message - with topic" do
		m = subject.to_message('Topic')

		m.data_type.should == 'RawDatum'
		m.topic.should == 'Topic'
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:value].should == 123
	end

	it "can be created from Message" do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a RawDatum
		dt.type.should == 'Memory usage'
		dt.group.should == 'RAM'
		dt.component.should == 'cache'
		dt.value.should == 123
	end

	it "can be converted to RawDataPoint" do
		rdp = subject.to_raw_data_point('magi', Time.at(2))

		rdp.location.should == 'magi'
		rdp.type.should == 'Memory usage'
		rdp.group.should == 'RAM'
		rdp.component.should == 'cache'
		rdp.time_stamp.should == 2
		rdp.value.should == 123
	end
end

