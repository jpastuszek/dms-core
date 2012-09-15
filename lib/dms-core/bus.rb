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

class Bus
	def self.bind(context, publisher_address, subscriber_address, publisher_options = {}, subscriber_options = {})
		if block_given?
			context.sub_bind(subscriber_address, subscriber_options) do |sub|
				context.pub_bind(publisher_address, publisher_options) do |pub|
					yield self.new(sub, pub)
				end
			end
		else
			sub = context.sub_bind(subscriber_address, subscriber_options)
			pub = context.pub_bind(publisher_address, publisher_options)
			self.new(sub, pub)
		end
	end

	def self.connect(context, publisher_address, subscriber_address, publisher_options = {}, subscriber_options = {})
		if block_given?
			context.sub_connect(publisher_address, subscriber_options) do |sub|
				context.pub_connect(subscriber_address, publisher_options) do |pub|
					yield self.new(sub, pub)
				end
			end
		else
			sub = context.sub_connect(publisher_address, subscriber_options)
			pub = context.pub_connect(subscriber_address, publisher_options)
			self.new(sub, pub)
		end
	end

	def initialize(sub, pub)
		@sub = sub
		@pub = pub
	end

	def on(data_type, topic = '', &callback)
		@sub.on(data_type, topic, &callback)
	end

	def send(data_type, options = {})
		@pub.send(data_type, options)
	end

	def on_raw(&callback)
		@sub.on_raw(&callback)
	end

	def send_raw(string, options = {})
		@pub.send_raw(string, options)
	end

	def socket
		@sub.socket
	end

	def receive!
		@sub.receive!
	end

	def close
		@pub.close
		@sub.close
	end

	def on_close(&callback)
		@sub.on_close(&callback)
	end

	def closed?
		@sub.closed? or @pub.closed?
	end
end

class ZeroMQ
	def bus_connect(publisher_address, subscriber_address, publisher_options = {}, subscriber_options = {}, &block)
		Bus.connect(self, publisher_address, subscriber_address, publisher_options, subscriber_options, &block)
	end

	def bus_bind(publisher_address, subscriber_address, publisher_options = {}, subscriber_options = {}, &block)
		Bus.bind(self, publisher_address, subscriber_address, publisher_options, subscriber_options, &block)
	end
end

