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

describe RawDataPoint do
	subject do
		RawDataPoint.new('magi', 'system/memory', 'cache', 123, Time.at(2.35))
	end

	it 'takes type, path, component and value' do
		subject.location.should == 'magi'
		subject.path.should == 'system/memory'
		subject.component.should == 'cache'
		subject.value.should == 123
		subject.time_stamp.should be_utc
		subject.time_stamp.should be_a(Time)
		subject.time_stamp.should == Time.at(2.35).utc
	end

	it 'can be converted to Message' do
		m = subject.to_message

		m.data_type.should == 'RawDataPoint'
		m.topic.should == ''
		m[:location].should == 'magi'
		m[:path].should == 'system/memory'
		m[:component].should == 'cache'
		m[:value].should == 123
		m[:time_stamp].should == 2.35

		expect {
			m.to_s
		}.to_not raise_error
	end

	it 'can be converted to Message - with topic' do
		m = subject.to_message('Topic')

		m.data_type.should == 'RawDataPoint'
		m.topic.should == 'Topic'
		m[:location].should == 'magi'
		m[:path].should == 'system/memory'
		m[:component].should == 'cache'
		m[:value].should == 123
		m[:time_stamp].should == 2.35
	end

	it 'can be created from Message' do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a RawDataPoint
		dt.location.should == 'magi'
		dt.path.should == 'system/memory'
		dt.component.should == 'cache'
		dt.value.should == 123
		dt.time_stamp.should be_utc
		dt.time_stamp.should be_a(Time)
		dt.time_stamp.should == Time.at(2.35).utc
	end

	it '#to_s gives nice printout' do
		subject.to_s.should == 'RawDataPoint[1970-01-01 00:00:02.350][magi:system/memory/cache]: 123'
	end
end

