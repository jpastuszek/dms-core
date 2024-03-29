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

shared_examples_for 'TagPattern machable' do
	it 'should match sub components with order' do
		subject.should be_match(TagPattern.new('java'))
		subject.should be_match(TagPattern.new('memory'))
		subject.should be_match(TagPattern.new('memory:HeapSpace'))
		subject.should be_match(TagPattern.new('java:memory'))
		subject.should_not be_match(TagPattern.new('memory:java'))
	end

	it 'should support regexp component matching' do
		subject.should be_match(TagPattern.new('/ja/'))
		subject.should be_match(TagPattern.new('/me.*ory/'))
		subject.should be_match(TagPattern.new('memory:/pace/'))
		subject.should be_match(TagPattern.new('java://:HeapSpace'))
		subject.should_not be_match(TagPattern.new('memory:/j/'))
	end

	it 'matching should be case insensitive' do
		subject.should be_match(TagPattern.new('MEMORY:heapspace'))
		subject.should be_match(TagPattern.new('memory:/SPA/'))
	end

	it 'matching should work with string' do
		subject.should be_match('MEMORY:heapspace')
		subject.should be_match('memory:/SPA/')
	end

	it 'should match against empty regexp pattern' do
		subject.should be_match(TagPattern.new('//'))
	end
end

describe Tag do
	subject do
		Tag.new('java:memory:HeapSpace:PermGem')
	end

	it "should allow access to its components" do
		subject[0].should == 'java'
		subject[1].should == 'memory'
		subject[2].should == 'HeapSpace'
		subject[3].should == 'PermGem'
	end

	it 'should convert to string' do
		subject.to_s.should == 'java:memory:HeapSpace:PermGem'
	end

	it "should strip white space around it" do
		Tag.new(' test   ').to_s.should == 'test'
	end

	it 'constructor argument is casted to string' do
		Tag.new(:test)[0].should == 'test'
	end

	it_behaves_like 'TagPattern machable'

	it 'should match TagExpression if any TagPattern maches this tag' do
		subject.should be_match(TagExpression.new('java://:HeapSpace, asfdasd, afsderw'))
		subject.should be_match(TagExpression.new('dfassde, MEMORY:heapspace, /me.*ory/'))
		subject.should_not be_match(TagExpression.new('ewrad, ewrad, fda'))

		subject.should be_match('dafssdf, memory:/SPA/, dafds')
		subject.should be_match('MEMORY:heapspace, dafssdf, memory:/SPA/, dafds')

		subject.should_not be_match('fads, dafssdf, fdas, dafds')
	end
end

describe TagSet do
	subject do
		TagSet[Tag.new('java:memory:HeapSpace:PermGem'), Tag.new('abc')]
	end

	it 'should convert to string in alphabetical order' do
		subject.to_s.should == 'abc, java:memory:HeapSpace:PermGem'
	end

	it 'should allow checkting if tag is there' do
		subject.member?(Tag.new('java:memory:HeapSpace:PermGem')).should be_true
	end

	it 'should convert to array' do
		subject.to_a.sort.should == [Tag.new('abc'), Tag.new('java:memory:HeapSpace:PermGem')]
	end

	it 'should store new tags' do
		subject.add(Tag.new('gear'))
		subject.to_s.should == 'abc, gear, java:memory:HeapSpace:PermGem'
	end

	it 'should construct from lazy formatted string' do
		ts = TagSet.new('   xyz,memory, java:memory:HeapSpace:PermGem,   location:magi ')
		ts.to_s.should == 'java:memory:HeapSpace:PermGem, location:magi, memory, xyz'
		ts.should include(Tag.new('location:magi'))
		ts.should include(Tag.new('memory'))
		ts.should include(Tag.new('xyz'))
		ts.should include(Tag.new('java:memory:HeapSpace:PermGem'))
	end

	it 'should construct from anything converable to array of strings' do
		ts = TagSet.new(Set['xyz', :abc, 1])
		ts.to_s.should == '1, abc, xyz'
		ts.should include(Tag.new('1'))
		ts.should include(Tag.new('abc'))
		ts.should include(Tag.new('xyz'))
	end

	it_behaves_like 'TagPattern machable'
	it 'should match abc tag' do
		subject.should be_match(TagPattern.new('abc'))
	end

	it 'should match TagExpression if all TagPatterns maches any tag in this set' do
		subject.should be_match(TagExpression.new('java://:HeapSpace, MEMORY, abc'))
		subject.should be_match(TagExpression.new('/me.*ory/'))
		subject.should_not be_match(TagExpression.new('MEMORY, abc, fda'))

		subject.should be_match('abc, memory:/SPA/')
		subject.should be_match('MEMORY:heapspace, memory:/SPA/')

		subject.should_not be_match('MEMORY:heapspace, memory:/SPA/, xyz')
	end
end

describe TagPattern do
	subject do
		TagPattern.new('java:/.*ry/:heap:/space/')
	end
	
	it 'should include Regexp components that are sourounded by //' do
		subject[0].should be_a(String)
		subject[1].should be_a(Regexp)
		subject[2].should be_a(String)
		subject[3].should be_a(Regexp)
	end

	it 'should convert to string' do
		subject.to_s.should == 'java:/.*ry/:heap:/space/'
	end
end

describe TagExpression do
	subject do
		TagExpression[TagPattern.new('java:memory://:/space/'), TagPattern.new('//')]
	end

	it 'should convert to string in alphabetical order' do
		subject.to_s.should == '//, java:memory://:/space/'
	end

	it 'should allow checkting if tag is there' do
		subject.member?(TagPattern.new('//')).should be_true
		subject.member?(TagPattern.new('/xyz/')).should be_false
	end

	it 'should convert to array' do
		subject.to_a.should include(TagPattern.new('//'))
		subject.to_a.should include(TagPattern.new('java:memory://:/space/'))
	end

	it 'should store new tags' do
		subject.add(Tag.new('gear'))
		subject.to_s.should == '//, gear, java:memory://:/space/'
	end

	it 'should construct from lazy formatted string' do
		ts = TagExpression.new('   xyz,memory, java:memory://:PermGem,   /loc/:magi ')
		ts.to_s.should == '/loc/:magi, java:memory://:PermGem, memory, xyz'
		ts.should include(TagPattern.new('/loc/:magi'))
		ts.should include(TagPattern.new('memory'))
		ts.should include(TagPattern.new('xyz'))
		ts.should include(TagPattern.new('java:memory://:PermGem'))
	end

	it 'should construct from anything converable to array of strings' do
		ts = TagExpression.new(Set['/xyz/', :abc, 1])
		ts.to_s.should == '/xyz/, 1, abc'
		ts.should include(TagPattern.new('1'))
		ts.should include(TagPattern.new('abc'))
		ts.should include(TagPattern.new('/xyz/'))
	end

	context 'conversion' do
		it 'from string' do
			ts = '   xyz,memory, java:memory://:PermGem,   /loc/:magi '.to_tag_expression
			ts.should be_a TagExpression
			ts.should include(TagPattern.new('/loc/:magi'))
			ts.should include(TagPattern.new('memory'))
			ts.should include(TagPattern.new('xyz'))
			ts.should include(TagPattern.new('java:memory://:PermGem'))
		end

		it 'from TagPattern' do
			ts = TagPattern.new('/loc/:magi').to_tag_expression
			ts.should be_a TagExpression
			ts.should include(TagPattern.new('/loc/:magi'))
		end

		it 'from itself' do
			ts = TagExpression[TagPattern.new('java:memory://:/space/'), TagPattern.new('//')].to_tag_expression
			ts.should include(TagPattern.new('java:memory://:/space/'))
			ts.should include(TagPattern.new('//'))
		end
	end
end

describe TagQuery do
	subject do
		TagQuery[
			TagExpression.new('xyz, memory, java:memory://:PermGem, /loc/:magi'),
			TagExpression.new('virtual, CPU usage:CPU://, /loc/:nina')
		]
	end

	it 'should convert to string in alphabetical order' do
		subject.to_s.should == '/loc/:magi, java:memory://:PermGem, memory, xyz | /loc/:nina, CPU usage:CPU://, virtual'
	end

	it 'should allow checkting if tag is there' do
		subject.member?(TagExpression.new('virtual, CPU usage:CPU://, /loc/:nina')).should be_true
		subject.member?(TagExpression.new('virtual, CPU usage:CPU://, /loc/:magi')).should be_false
	end

	it 'should convert to array' do
		subject.to_a.should include(TagExpression.new('xyz, memory, java:memory://:PermGem, /loc/:magi'))
		subject.to_a.should include(TagExpression.new('virtual, CPU usage:CPU://, /loc/:nina'))
	end

	it 'should store new tag expressions' do
		subject.add(TagExpression.new('test, jj'))
		subject.to_s.should == '/loc/:magi, java:memory://:PermGem, memory, xyz | /loc/:nina, CPU usage:CPU://, virtual | jj, test'
	end

	it 'should construct from lazy formatted string' do
		ts = TagQuery.new(' abc, zz:yy:qq|  xyz,memory, java:memory://:PermGem|/loc/:magi ')
		ts.to_s.should == '/loc/:magi | abc, zz:yy:qq | java:memory://:PermGem, memory, xyz'
		ts.should have(3).tag_expressions
		ts.should include(TagExpression.new('abc, zz:yy:qq'))
		ts.should include(TagExpression.new('xyz,memory, java:memory://:PermGem'))
		ts.should include(TagExpression.new('/loc/:magi'))
	end

	it 'should construct from anything converable to array of strings' do
		ts = TagQuery.new(['abc, zz:yy:qq', 'xyz,memory, java:memory://:PermGem', '/loc/:magi'])
		ts.should have(3).tag_expressions
		ts.should include(TagExpression.new('abc, zz:yy:qq'))
		ts.should include(TagExpression.new('xyz,memory, java:memory://:PermGem'))
		ts.should include(TagExpression.new('/loc/:magi'))
	end

	context 'conversion' do
		it 'from string' do
			ts = ' abc, zz:yy:qq|  xyz,memory, java:memory://:PermGem|/loc/:magi '.to_tag_query
			ts.should be_a TagQuery
			ts.should have(3).tag_expressions
			ts.should include(TagExpression.new('abc, zz:yy:qq'))
			ts.should include(TagExpression.new('xyz,memory, java:memory://:PermGem'))
			ts.should include(TagExpression.new('/loc/:magi'))
		end

		it 'from TagPattern' do
			ts = TagPattern.new('/loc/:magi').to_tag_query
			ts.should be_a TagQuery
			ts.should include(TagExpression.new('/loc/:magi'))
		end

		it 'from TagExpression' do
			ts = TagExpression.new('/loc/:magi, abc:xyz').to_tag_query
			ts.should be_a TagQuery
			ts.should include(TagExpression.new('/loc/:magi, abc:xyz'))
		end

		it 'from itself' do
			ts = subject.to_tag_query
			ts.should be_a TagQuery
			ts.to_a.should include(TagExpression.new('xyz, memory, java:memory://:PermGem, /loc/:magi'))
			ts.to_a.should include(TagExpression.new('virtual, CPU usage:CPU://, /loc/:nina'))
		end
	end
end

