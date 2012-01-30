require 'msgpack'

class Message
	attr_reader :data_type
	attr_reader :topic
	attr_reader :encoding
	attr_reader :version
	attr_reader :body

	def self.load(str)
		header, body = *str.split("\n\n", 2)

		body = MessagePack.unpack(body)
		header = *header.split("\n", 4)

		data_type, topic = header.shift.split('/', 2)
		encoding, version = *header

		self.new(data_type, topic, encoding, version) do |b|
			body.each_pair do |key, value|
				b[key.to_sym] = value
			end
		end
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
		@body.to_msgpack
	end

	def to_s
		header + "\n\n" + body
	end
end

