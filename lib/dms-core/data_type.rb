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

	def self.from_message(message)
		data_type = @@data_types[message.data_type] or raise DataTypeError::UnknowndDataTypeError, message.data_type
		data_type.from_message(message)
	end

	def self.to_time(value)
		value.is_a?(Time) ? value.utc : Time.at(value.to_f).utc
	end
end

