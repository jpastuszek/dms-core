require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DataSetQuery do
	subject do
		DataSetQuery.new('abc123', 'location:/magi\./, system:memory', Time.at(100), Time.at(0), 1)
	end

	it 'takes query id' do
		subject.query_id.should == 'abc123'
	end

	it 'takes tag expression' do
		subject.tag_expression.should be_a TagExpression
		subject.tag_expression.to_s.should == 'location:/magi\./, system:memory'
	end

	it 'takes time_from, time_to in UTC' do
		subject.time_from.should be_a(Time)
		subject.time_from.should be_utc
		subject.time_to.should be_a(Time)
		subject.time_to.should be_utc
	end

	it 'takse granularity' do
		subject.granularity.should == 1.0
	end

	it 'can be converted to Message' do
		m = subject.to_message
		m.data_type.should == 'DataSetQuery'
		m.topic.should == ''

		m[:query_id].should == 'abc123'
		m[:tag_expression].should == 'location:/magi\./, system:memory'
		m[:time_from].should == 100
		m[:time_to].should == 0
		m[:granularity].should == 1.0

		expect {
			m.to_s
		}.to_not raise_error
	end

	it 'can be created from Message' do
		dt = DataType.from_message(subject.to_message)
		dt.should be_a DataSetQuery

		dt.tag_expression.should be_a TagExpression
		Tag.new('location:magi.sigquit.net').should be_match(dt.tag_expression)
		Tag.new('system:memory').should be_match(dt.tag_expression)
		Tag.new('xyz').should_not be_match(dt.tag_expression)
		dt.time_from.should be_a(Time)
		dt.time_from.should be_utc
		dt.time_from.should == Time.at(100).utc
		dt.time_to.should be_a(Time)
		dt.time_to.should be_utc
		dt.time_to.should == Time.at(0).utc
		dt.granularity.should == 1.0
	end

	it '#to_s gives nice printout' do
		subject.to_s.should == 'DataSetQuery[abc123][location:/magi\\./, system:memory]: 1970-01-01 00:01:40.000 1970-01-01 00:00:00.000'
	end
end


