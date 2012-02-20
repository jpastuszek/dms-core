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

require 'msgpack'

class Message
	class SerializationError < IOError
		class BodyEncodingError < SerializationError
			def initialize(body, error)
				super "failed to encode message body: #{body.inspect}: #{error.class}: #{error.message}"
			end
		end
	end

	class DeserializationError < IOError
		class MissingHeaderBodyDelimiterError < DeserializationError
			def initialize(packet)
				super "missing header body delimiter: #{packet.inspect}"
			end
		end

		class BodyDecodingError < DeserializationError
			def initialize(encoding, error, body)
				super "failed to decode body encoded with '#{encoding}': #{error.class}: #{error.message}: #{body.inspect}" 
			end
		end
	
		class BadHeaderError < DeserializationError
			def initialize(header)
				super "failed to parse header: #{header.inspect}" 
			end
		end

		class UnsupportedEncodingError < DeserializationError
			def initialize(encoding)
				super "don't know how to decode message encoded in: #{encoding}" 
			end
		end

		class BodyNotHashError < DeserializationError
			def initialize(body)
				super "expeced body to be a Hash, got: #{body.inspect}" 
			end
		end
	end

	attr_reader :data_type
	attr_reader :topic
	attr_reader :encoding
	attr_reader :version
	attr_reader :body

	def self.load(str)
		header, body = *str.split("\n\n", 2)
		raise DeserializationError::MissingHeaderBodyDelimiterError, str unless header and body

		h = *header.split("\n", 3)
		raise DeserializationError::BadHeaderError, header unless h.length == 3

		data_type, topic = h.shift.split('/', 2)
		version, encoding = *h
		raise DeserializationError::BadHeaderError, header unless data_type and topic and encoding and version

		begin
			case encoding
			when 'msgpack'
				body = MessagePack.unpack(body)
			else
				raise DeserializationError::UnsupportedEncodingError, encoding
			end
		rescue MessagePack::UnpackError => e
			raise DeserializationError::BodyDecodingError.new(encoding, e, body)
		end

		raise DeserializationError::BodyNotHashError, body unless body.is_a? Hash

		self.new(data_type, topic, version, encoding) do |b|
			body.each_pair do |key, value|
				b[key.to_sym] = value
			end
		end
	end

	def self.load_split(header, body)
		self.load("#{header}\n\n#{body}")
	end

	def initialize(data_type, topic = '', version = 0, encoding = 'msgpack')
		@data_type = data_type.to_s
		@topic = topic.to_s
		@version = version.to_i
		@encoding = encoding.to_s
		@body = {}
		yield(@body)
	end

	def [](key)
		@body[key]
	end

	def header
		"#{data_type}/#{topic}\n#{version}\n#{encoding}"
	end

	def body
		begin
			@body.to_msgpack
		rescue => e
			raise SerializationError::BodyEncodingError.new(@body, e)
		end
	end

	def to_s
		header + "\n\n" + body
	end
end

