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
		@time_stamp = DataType.to_time(time_stamp)
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
			body[:time_stamp] = @time_stamp.to_f
		end
	end

	def to_s
		"RawDataPoint[#{Time.at(time_stamp).utc.strftime('%Y-%m-%d %H:%M:%S.%L')}][#{location}:#{path}/#{component}]: #{value}"
	end

	register(self)
end

