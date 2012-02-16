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
end

