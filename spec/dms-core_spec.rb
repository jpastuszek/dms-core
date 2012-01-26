require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Message" do
  it "can be constructed" do
		m = Message.new('RawDatum') do |body|
			body[:type] = 'CPU Usage'
			body[:group] = 'CPU0'
			body[:component] = 'nice'
			body[:value] = 0.25
		end

		m.data_type.should == 'RawDatum'
		m.topic.should == ''
		m.encoding.should == 'msgpack'
		m.version.should == 0

		m[:type].should == 'CPU Usage'
		m[:group].should == 'CPU0'
		m[:component].should == 'nice'
		m[:value].should == 0.25
  end
	
	it "can be serialized" do
		m = Message.new('Test') do |b|
			b[:abc] = 'xyz'
			b[:num] = 123
		end

		m.to_s.should == <<-EOM.strip
Test/
msgpack
0

\202\243num{\243abc\243xyz
		EOM
	end

	it "can be deserialized" do
		m = Message.load(<<-EOM.strip)
Test/Topic
msgpack
0

\202\243num{\243abc\243xyz
		EOM

		m.data_type.should == 'Test'
		m.topic.should == 'Topic'
		m.encoding.should == 'msgpack'
		m.version.should == 0

		m[:abc].should == 'xyz'
		m[:num].should == 123
	end
end

