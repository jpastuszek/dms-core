require 'set'

class Tag < Array
	def initialize(value)
		super value.to_s.strip.split(':')
	end

	def to_s
		join(':')
	end

	def match?(pattern)
		pattern = pattern.is_a?(TagPattern) ? pattern : TagPattern.new(pattern)
		tag = self.dup
	
		# stupid and slow but works
		while tag.length >= pattern.length
			return true if tag.take(pattern.length).zip(pattern).all? do |tag_component, pattern_component|
				if pattern_component.is_a? Regexp
					tag_component =~ pattern_component
				else
					tag_component.downcase == pattern_component.downcase
				end
			end
			tag.shift
		end

		return false
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

	def match?(pattern)
		one? do |tag|
			tag.match?(pattern)
		end
	end
end

class TagPattern < Tag
	def initialize(value)
		super
		map! do |component| 
			if component[0] == '/' and component[-1] == '/'
				Regexp.new(component.slice(1...-1), Regexp::EXTENDED | Regexp::IGNORECASE)
			else
				component
			end
		end
	end
end

