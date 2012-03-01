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

class DataSetQuery < DataType
	attr_reader :query_id
	attr_reader :tag_expression
	attr_reader :time_from
	attr_reader :time_to
	attr_reader :granularity

	def initialize(query_id, tag_expression, time_from, time_to, granularity)
		@query_id = query_id.to_s
		@tag_expression = tag_expression.is_a?(TagExpression) ? tag_expression : TagExpression.new(tag_expression)
		@time_from = DataType.to_time(time_from)
		@time_to = DataType.to_time(time_to)
		@granularity = granularity.to_f
	end

	def self.from_message(message)
		self.new(
			message[:query_id], 
			TagExpression.new(message[:tag_expression]), 
			Time.at(message[:time_from]).utc,
			Time.at(message[:time_to]).utc,
			message[:granularity]
		)
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:query_id] = @query_id
			body[:tag_expression] = @tag_expression.to_s
			body[:time_from] = @time_from.to_f
			body[:time_to] = @time_to.to_f
			body[:granularity] = @granularity
		end
	end

	def to_s
		"DataSetQuery[#{@query_id}][#{@tag_expression.to_s}]<#{Time.at(@time_from).utc.strftime('%Y-%m-%d %H:%M:%S.%L')},#{@time_from.to_f - @time_to.to_f}>@#{@granularity}"
	end

	register(self)
end

