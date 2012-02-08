require 'dms-core/data_type'

class RawDatum < DataType
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

	def self.from_message(message)
		self.new(
			message[:type], 
			message[:group], 
			message[:component], 
			message[:value]
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:type] = @type
			body[:group] = @group
			body[:component] = @component
			body[:value] = @value
		end
	end

	def to_raw_data_point(location, time_stamp)
		RawDataPoint.new(location, type, group, component, time_stamp, value)
	end

	def to_s
		"RawDatum[#{type}/#{group}/#{component}]: #{value}"
	end

	register(self)
end

