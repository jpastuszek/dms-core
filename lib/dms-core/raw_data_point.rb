require 'dms-core/data_type'

class RawDataPoint < DataType
	attr_reader :location
	attr_reader :path
	attr_reader :component
	attr_reader :time_stamp
	attr_reader :value

	def initialize(location, path, component, value, time_stamp = Time.now.utc)
		@location = location
		@path = path
		@component = component
		@value = value
		@time_stamp = time_stamp.to_f
	end

	def self.from_message(message)
		self.new(
			message[:location], 
			message[:path], 
			message[:component], 
			message[:value],
			message[:time_stamp]
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:location] = @location
			body[:path] = @path
			body[:component] = @component
			body[:value] = @value
			body[:time_stamp] = @time_stamp
		end
	end

	def to_s
		"RawDataPoint[#{Time.at(time_stamp).utc.strftime('%Y-%m-%d %H:%M:%S.%L')}][#{location}:#{path}/#{component}]: #{value}"
	end

	register(self)
end

