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
					new_data << [time.to_f, value]
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
	attr_reader :time_from
	attr_reader :time_span
	attr_reader :component_data

	def initialize(type_name, tag_set, time_from, time_span, &block)
		@type_name = type_name.to_s
		@tag_set = tag_set.is_a?(TagSet) ? tag_set : TagSet.new(tag_set)
		@time_from = DataType.to_time(time_from)
		@time_span = time_span.to_f
		@component_data = ComponentData.new(&block)
	end

	def self.from_message(message)
		self.new(
			message[:type_name], 
			TagSet.new(message[:tag_set]), 
			Time.at(message[:time_from]).utc,
			message[:time_span]
		) do
			message[:component_data].each_pair do |component, data|
				data.each do |time, value|
					component_data component, time, value
				end
			end
		end
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:type_name] = @type_name
			body[:tag_set] = @tag_set.to_s
			body[:time_from] = @time_from.to_f
			body[:time_span] = @time_span
			body[:component_data] = @component_data.to_transport
		end
	end
	
	def to_s
		"DataSet[#{type_name}][#{tag_set.to_s}]: #{component_data.keys.map{|k| k.to_s}.sort.map{|k| "#{k}(#{component_data[k].length})"}.join(', ')}"
	end

	register(self)
end

