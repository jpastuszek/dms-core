require 'dms-core/message'

class RawDatum
	attr_reader :type
	attr_reader :group
	attr_reader :component
	attr_reader :value

	def initialize(type, group, component, value)
		@type = type
		@group = group
		@component = component
		@value = value
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:type] = @type
			body[:group] = @group
			body[:component] = @component
			body[:value] = @value
		end
	end
end

