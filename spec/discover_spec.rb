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

describe Discover do
	subject do
		Discover.new('magi', 'data-processor')
	end

	it 'host_name and program' do
		subject.host_name.should == 'magi'
		subject.program.should == 'data-processor'
	end

	it 'takes case insensitive extended regexp host_name' do
		dt = Discover.new('/magi/', 'data-processor')
		dt.host_name.should == /magi/xi

		dt = DataType.from_message(Message.load(dt.to_message.to_s))

		dt.should be_a Discover
		dt.host_name.should == /magi/xi
		dt.program.should == 'data-processor'
	end

	it 'can be converted to Message' do
		m = subject.to_message

		m.data_type.should == 'Discover'
		m.topic.should == ''
		m[:host_name].should == 'magi'
		m[:program].should == 'data-processor'

		expect {
			m.to_s
		}.to_not raise_error
	end

	it 'can be converted to Message - with topic' do
		m = subject.to_message('Topic')

		m.data_type.should == 'Discover'
		m.topic.should == 'Topic'
		m[:host_name].should == 'magi'
		m[:program].should == 'data-processor'
	end

	it 'can be created from Message' do
		dt = DataType.from_message(subject.to_message)

		dt.should be_a Discover
		dt.host_name.should == 'magi'
		dt.program.should == 'data-processor'
	end

	it '#to_s gives nice printout' do
		subject.to_s.should == 'Discover[magi/data-processor]'
		Discover.new('/magi/', 'data-processor').to_s.should == 'Discover[/magi//data-processor]'
	end
end


