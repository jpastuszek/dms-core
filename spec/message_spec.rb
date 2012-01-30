require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'msgpack'

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
			subject.version.should == 0
			subject.encoding.should == 'msgpack'
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
0
msgpack

			EOM
			s.should include("xyz")
		end

		specify "of header only" do
			subject.header.should == "RawDatum/id123\n0\nmsgpack"
		end

		specify "of body only" do
			subject.body.should include("xyz")
		end
	end

	it "can be serialized and deserialized" do
		m = Message.load(subject.to_s)

		m.data_type.should == 'RawDatum'
		m.topic.should == 'id123'
		m.version.should == 0
		m.encoding.should == 'msgpack'

		m[:abc].should == 'xyz'
		m[:num].should == 123
		m[:bool].should == true
		m[:arr].should == [1, 2]
	end

	describe "deserialization error" do
		describe Message::DeserializationError::MissingHeaderBodyDelimiterError do
			it 'should be raised if \n\n is not in message' do
				expect {
					Message.load("RawDatum/\n0\nmsgpack\n#{subject.body}")
				}.to raise_error Message::DeserializationError::MissingHeaderBodyDelimiterError
			end
		end

		describe Message::DeserializationError::BadHeaderError do
			it 'should be raised if header value is missing' do
				expect {
					Message.load("RawDatum/\nmsgpack\n\n#{subject.body}")
				}.to raise_error Message::DeserializationError::BadHeaderError
			end

			it 'should be raised if header topic delimiter is not /' do
				expect {
					Message.load("RawDatum\ntest\n0\nmsgpack\n\n#{subject.body}")
				}.to raise_error Message::DeserializationError::BadHeaderError

				expect {
					Message.load("RawDatum-test\n0\nmsgpack\n\n#{subject.body}")
				}.to raise_error Message::DeserializationError::BadHeaderError
			end
		end

		describe Message::DeserializationError::UnsupportedEncodingError do
			it "should be raised when encoding is not supported" do
				expect {
					Message.load("RawDatum/\n0\nbogous\n\n#{subject.body}")
				}.to raise_error Message::DeserializationError::UnsupportedEncodingError
			end
		end

		describe Message::DeserializationError::BodyDecodingError do
			it "should be raised when encoded body cannot be decoded" do
				expect {
					Message.load("RawDatum/\n0\nmsgpack\n\nXXX#{subject.body}")
				}.to raise_error Message::DeserializationError::BodyDecodingError
			end
		end

		describe Message::DeserializationError::BodyNotHashError do
			it "should be raised when encoded body decodes to something that is not a Hash" do
				expect {
					Message.load("RawDatum/\n0\nmsgpack\n\n#{[:a, :b, :c].to_msgpack}")
				}.to raise_error Message::DeserializationError::BodyNotHashError, 'expeced body to be a Hash, got: ["a", "b", "c"]'
			end
		end
	end
end

