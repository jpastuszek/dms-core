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

require 'dms-core/message'

class DataType
	class DataTypeError < ArgumentError
		class UnknowndDataTypeError < DataTypeError
			def initialize(data_type_name)
				super "unknown data type: #{data_type_name}"
			end
		end
	end

	@@data_types ||= {}

	def self.register(data_type_class)
		@@data_types[data_type_class.name] = data_type_class
	end

	def self.data_type(data_type_name)
		@@data_types[data_type_name] or raise DataTypeError::UnknowndDataTypeError, data_type_name
	end

	def self.from_message(message)
		data_type = data_type(message.data_type)
		data_type.from_message(message)
	end

	def self.to_time(value)
		value.is_a?(Time) ? value.utc : Time.at(value.to_f).utc
	end
end

