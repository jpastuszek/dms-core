require 'dms-core/data_type'

class RawDataPoint < DataType
	attr_reader :location
	attr_reader :type
	attr_reader :group
	attr_reader :component
	attr_reader :time_stamp
	attr_reader :value

	def initialize(location, type, group, component, time_stamp, value)
		@location = location
		@type = type
		@group = group
		@component = component
		@time_stamp = time_stamp.to_i
		@value = value
	end

	def self.from_message(message)
		self.new(
			message[:location], 
			message[:type], 
			message[:group], 
			message[:component], 
			message[:time_stamp], 
			message[:value]
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:location] = @location
			body[:type] = @type
			body[:group] = @group
			body[:component] = @component
			body[:time_stamp] = @time_stamp
			body[:value] = @value
		end
	end

	register(self)
end

