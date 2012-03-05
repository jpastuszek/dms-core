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

describe Hello do
	subject do
		Hello.new('magi', 'data-processor', 123)
	end

	it 'host_name, program and pid no' do
		subject.host_name.should == 'magi'
		subject.program.should == 'data-processor'
		subject.pid.should == 123
	end

	it 'can be converted to Message' do
		m = subject.to_message

		m.data_type.should == 'Hello'
		m.topic.should == ''
		m[:host_name].should == 'magi'
		m[:program].should == 'data-processor'
		m[:pid].should == 123

		expect {
			m.to_s
		}.to_not raise_error
	end

	it 'can be converted to Message - with topic' do
		m = subject.to_message('Topic')

		m.data_type.should == 'Hello'
		m.topic.should == 'Topic'
		m[:host_name].should == 'magi'
		m[:program].should == 'data-processor'
		m[:pid].should == 123
	end

	it 'can be created from Message' do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a Hello
		dt.host_name.should == 'magi'
		dt.program.should == 'data-processor'
		dt.pid.should == 123
	end

	it '#to_s gives nice printout' do
		subject.to_s.should == 'Hello[magi/data-processor:123]'
	end
end



