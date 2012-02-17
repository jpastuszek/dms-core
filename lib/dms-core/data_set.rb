require 'dms-core/data_type'
require 'dms-core/tag'

class DataSet < DataType
	class ComponentData < Hash
		def initialize(&block)
			instance_eval &block
		end

		def to_transport
			transport = {}

			each_pair do |component, data|
				new_data = (transport[component] = [])
				data.map do |time, value|
					new_data << time.to_f
					new_data << value
				end
			end

			transport
		end

		def component_data(name, time, value)
			data = (self[name.to_s] ||= [])
			data << [DataType.to_time(time), value]
		end
	end

	attr_reader :type_name
	attr_reader :tag_set
	attr_reader :unit
	attr_reader :time_from
	attr_reader :time_to
	attr_reader :component_data

	def initialize(type_name, tag_set, unit, time_from, time_to, &block)
		@type_name = type_name.to_s
		@tag_set = tag_set.is_a?(TagSet) ? tag_set : TagSet.new(tag_set)
		@unit = unit.to_s
		@time_from = DataType.to_time(time_from)
		@time_to = DataType.to_time(time_to)
		@component_data = ComponentData.new(&block)
	end

	def self.from_message(message)
		self.new(
			message[:type_name], 
			TagSet.new(message[:tag_set]), 
			message[:unit], 
			Time.at(message[:time_from]).utc,
			Time.at(message[:time_to]).utc,
		) do
			message[:component_data].each_pair do |component, data|
				data.each_slice(2) do |time, value|
					component_data component, time, value
				end
			end
		end
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:type_name] = @type_name
			body[:tag_set] = @tag_set.to_s
			body[:unit] = @unit
			body[:time_from] = @time_from.to_f
			body[:time_to] = @time_to.to_f
			body[:component_data] = @component_data.to_transport
		end
	end

	def to_s
		"DataSet[#{type_name}][#{tag_set.to_s}]: #{component_data.keys.map{|k| k.to_s}.sort.map{|k| "#{k}(#{component_data[k].length})"}.join(', ')}"
	end

	register(self)
end

