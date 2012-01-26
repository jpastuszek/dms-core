require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Message do
	subject do
		Message.new('RawDatum', 'id123') do |body|
			body[:type] = 'CPU Usage'
			body[:group] = 'CPU0'
			body[:component] = 'nice'
			body[:value] = 0.25
			body[:abc] = 'xyz'
			body[:bool] = true
			body[:num] = 123
			body[:arr] = [1, 2]
		end
	end

	describe "access" do
		specify "to header data" do
			subject.data_type.should == 'RawDatum'
			subject.topic.should == 'id123'
			subject.encoding.should == 'msgpack'
			subject.version.should == 0
		end

		specify "to body data" do
			subject[:type].should == 'CPU Usage'
			subject[:group].should == 'CPU0'
			subject[:component].should == 'nice'
			subject[:value].should == 0.25
		end
	end
	
	describe "serialization" do
		specify "of whole message" do
			s = subject.to_s
			s.start_with?(<<-EOM).should == true
RawDatum/id123
msgpack
0

			EOM
			s.should include("xyz")
		end

		specify "of header only" do
			subject.header.should == "RawDatum/id123\nmsgpack\n0"
		end

		specify "of body only" do
			subject.body.should include("xyz")
		end
	end

	it "can be serialized and deserialized" do
		m = Message.load(subject.to_s)

		m.data_type.should == 'RawDatum'
		m.topic.should == 'id123'
		m.encoding.should == 'msgpack'
		m.version.should == 0

		m[:abc].should == 'xyz'
		m[:num].should == 123
		m[:bool].should == true
		m[:arr].should == [1, 2]
	end
end

