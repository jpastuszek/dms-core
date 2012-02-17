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
end

