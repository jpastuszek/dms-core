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

require 'set'

class Tag < Array
	def initialize(value)
		super value.to_s.strip.split(':')
	end

	def to_s
		join(':')
	end

	def match?(value)
		value.to_tag_expression.any? do |pattern|
			match_pattern(pattern)
		end
	end

	def inspect
		"Tag#{super}"
	end

	private

	def match_pattern(pattern)
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
		to_a.map{|tag| tag.to_s}.sort.join(', ')
	end

	def match?(value)
		value.to_tag_expression.all? do |pattern|
			self.any? do |tag|
				tag.match? pattern
			end
		end
	end
end

class TagPattern < Array
	def initialize(value)
		super value.to_s.strip.split(':')
		map! do |component| 
			if component[0] == '/' and component[-1] == '/'
				Regexp.new(component.slice(1...-1), Regexp::EXTENDED | Regexp::IGNORECASE)
			else
				component
			end
		end
	end

	def to_s
		map do |component| 
			if component.is_a? Regexp
				component.inspect.scan(/\/.*\//)
			else
				component.to_s
			end
		end.join(':')
	end

	def to_tag_expression
		TagExpression.new([self])
	end

	def to_tag_query
		to_tag_expression.to_tag_query
	end

	def inspect
		"TagPattern#{super}"
	end
end

class TagExpression < Set
	def initialize(value)
		if value.is_a? String
			super value.split(',').map{|tag| TagPattern.new(tag)}
		else
			super value.to_a.map{|it| it.is_a?(TagPattern) ? it : TagPattern.new(it)}
		end
	end

	def to_s
		to_a.map{|tag| tag.to_s}.sort.join(', ')
	end

	def to_tag_expression
		self
	end

	def to_tag_query
		TagQuery.new([self])
	end

	def inspect
		"TagExpression#{to_a.map{|tag| tag.to_s}.sort.inspect}"
	end
end

class String
	def to_tag_expression
		TagExpression.new(self)
	end
end

class TagQuery < Set
	def initialize(value)
		if value.is_a? String
			super value.split('|').map{|tag_expression| TagExpression.new(tag_expression)}
		else
			super value.to_a.map{|it| it.is_a?(TagExpression) ? it : TagExpression.new(it)}
		end
	end

	def to_s
		to_a.map{|tag_expression| tag_expression.to_s}.sort.join(' | ')
	end

	def to_tag_query
		self
	end

	def inspect
		"TagQuery#{to_a.map{|tag_expression| tag_expression.to_s}.sort.inspect}"
	end
end

class String
	def to_tag_query
		TagQuery.new(self)
	end
end

