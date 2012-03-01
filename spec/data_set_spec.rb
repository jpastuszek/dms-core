# Copyright (c) 2012 Jakub Pastuszek
#
# This file is part of Distributed Monitoring System.
#
# Distributed Monitoring System is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Distributed Monitoring System is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Distributed Monitoring System.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DataSet do
	subject do
		DataSet.new('memory', 'location:magi, system:memory', Time.at(100), 100) do
			component_data 'free', 1, 1234
			component_data 'free', 2, 1235
			component_data 'used', 1, 3452
			component_data 'used', 2, 3451
		end
	end

	it 'takes tag set' do
		subject.tag_set.should be_a TagSet
		subject.tag_set.should be_match('location:magi')
		subject.tag_set.should be_match('system:memory')
	end

	it 'takes type_name' do
		subject.type_name.should == 'memory'
	end

	it 'takes time_from in UTC, time_span' do
		subject.time_from.should be_a Time
		subject.time_from.should be_utc
		subject.time_span.should be_a Float
	end

	it 'takes component data as a hash' do
		subject.component_data.should be_a Hash
		subject.component_data.should have_key('used')
		subject.component_data['used'][0][0].should be_a Time
		subject.component_data['used'][0][0].should be_utc
		subject.component_data['used'][0][0].should == Time.at(1).utc
		subject.component_data['used'][0][1].should == 3452
		subject.component_data.should have_key('free')
	end

	it 'can be converted to Message' do
		m = subject.to_message
		m.data_type.should == 'DataSet'
		m.topic.should == ''

		m[:tag_set].should == 'location:magi, system:memory'
		m[:type_name].should == 'memory'
		m[:time_from].should == 100
		m[:time_span].should == 100.0
		m[:component_data].should include('free')
		m[:component_data]['free'].should == [1.0, 1234, 2.0, 1235]
		m[:component_data].should include('used')
		m[:component_data]['used'].should == [1.0, 3452, 2.0, 3451]

		expect {
			m.to_s
		}.to_not raise_error
	end

	it 'can be created from Message' do
		dt = DataType.from_message(subject.to_message)
		dt.should be_a DataSet

		dt.tag_set.should be_a TagSet
		dt.tag_set.should be_match('location:magi')
		dt.tag_set.should be_match('system:memory')
		dt.time_from.should be_a Time
		dt.time_from.should be_utc
		dt.time_span.should be_a Float
		dt.time_span.should == 100.0
		dt.component_data.should be_a Hash
		dt.component_data.should have_key('used')
		dt.component_data['used'][0][0].should be_a Time
		dt.component_data['used'][0][0].should be_utc
		dt.component_data['used'][0][0].should == Time.at(1).utc
		dt.component_data['used'][0][1].should == 3452
		dt.component_data.should have_key('free')
	end

	it '#to_s gives nice printout' do
		subject.to_s.should == 'DataSet[memory][location:magi, system:memory]: free(2), used(2)'
	end
end

