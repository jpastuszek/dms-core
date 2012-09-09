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

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'dms-core'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

require 'capture-output'
require 'tmpdir'
require 'tempfile'
require 'retry-this'
require 'timeout'

def keep_trying
	RetryThis.retry_this(
		:times => 10,
		:sleep => 0.01,
		:error_types => [Timeout::Error]
	) do |attempt|
		Timeout.timeout(0.01) do
			yield
		end
	end
end

require 'dms-core/data_type'

class TestMessage < DataType
	attr_reader :value

	def initialize(value)
		@value = value
	end

	def self.from_message(message)
		self.new(message[:value])
	end

	def to_message(topic = '')
		Message.new(self.class.name, topic, 0) do |body|
			body[:value] = @value
		end
	end

	def to_s
		"#{self.class.name}[#{value}]"
	end

	def ==(other)
		return false unless other.instance_of? self.class
		value == other.value
	end

	register(self)
end

class TestMessageA < TestMessage
	register(self)
end

class TestMessageB < TestMessage
	register(self)
end

class TestMessageUnregistered < TestMessage
end


