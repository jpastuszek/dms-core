shared_examples_for 'TagPattern machable' do
	it 'should match sub components with order' do
		TagPattern.new('java').should be_match(subject)
		TagPattern.new('memory').should be_match(subject)
		TagPattern.new('memory:HeapSpace').should be_match(subject)
		TagPattern.new('java:memory').should be_match(subject)
		TagPattern.new('memory:java').should_not be_match(subject)
	end

	it 'should support regexp component matching' do
		TagPattern.new('/ja/').should be_match(subject)
		TagPattern.new('/me.*ory/').should be_match(subject)
		TagPattern.new('memory:/pace/').should be_match(subject)
		TagPattern.new('java://:HeapSpace').should be_match(subject)
		TagPattern.new('memory:/j/').should_not be_match(subject)
	end

	it 'matching should be case insensitive' do
		TagPattern.new('MEMORY:heapspace').should be_match(subject)
		TagPattern.new('memory:/SPA/').should be_match(subject)
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
		TagPattern.new('abc').should be_match(subject)
	end
end

