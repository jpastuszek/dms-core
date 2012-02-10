require 'dms-core/data_type'

class RawDataPoint < DataType
	attr_reader :location
	attr_reader :type
	attr_reader :group
	attr_reader :component
	attr_reader :time_stamp
	attr_reader :value

	def initialize(location, type, group, component, value, time_stamp)
		@location = location
		@type = type
		@group = group
		@component = component
		@value = value
		@time_stamp = time_stamp.to_f
	end

	def self.from_message(message)
		self.new(
			message[:location], 
			message[:type], 
			message[:group], 
			message[:component], 
			message[:value],
			message[:time_stamp]
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:location] = @location
			body[:type] = @type
			body[:group] = @group
			body[:component] = @component
			body[:value] = @value
			body[:time_stamp] = @time_stamp
		end
	end

	def to_s
		"RawDataPoint[#{location}][#{Time.at(time_stamp).utc.strftime('%Y-%m-%d %H:%M:%S.%L')}][#{type}/#{group}/#{component}]: #{value}"
	end

	register(self)
end

