require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe RawDatum do
	it "takes type, group, component and value" do
		rd = RawDatum.new('Memory usage', 'RAM', 'cache', 123)
		rd.type.should == 'Memory usage'
		rd.group.should == 'RAM'
		rd.component.should == 'cache'
		rd.value.should == 123
	end

	it "can be converted to Message" do
		m = RawDatum.new('Memory usage', 'RAM', 'cache', 123).to_message

		m.data_type.should == 'RawDatum'
		m.topic.should == ''
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:value].should == 123
	end

	it "can be converted to Message - with topic" do
		m = RawDatum.new('Memory usage', 'RAM', 'cache', 123).to_message('Topic')

		m.data_type.should == 'RawDatum'
		m.topic.should == 'Topic'
		m[:type].should == 'Memory usage'
		m[:group].should == 'RAM'
		m[:component].should == 'cache'
		m[:value].should == 123
	end
end

