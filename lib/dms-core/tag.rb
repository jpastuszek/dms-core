require 'set'

class Tag < Array
	def initialize(string)
		super string.to_s.strip.split(':')
	end

	def to_s
		join(':')
	end
end

class TagSet < Set
	def initialize(value)
		if value.is_a? String
			super value.split(',').map{|tag| Tag.new(tag)}
		else
			super value.to_a.map{|it| it.is_a?(Tag) ? it : Tag.new(it)}
		end
	end

	def to_s
		to_a.sort.map{|tag| tag.to_s}.join(', ')
	end
end

class TagPattern < Tag
	def match?(tag)
		tag = tag.is_a?(Tag) ? tag.dup : Tag.new(tag)

		# stupid and slow but works
		while tag.length >= length
			return true if tag.take(length) == self
			tag.shift
		end

		return false
	end
end

