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

require 'rubytree'

class EventCallbackRegister
	class Handle
		def initialize(node, callback)
			@node = node
			@callback = callback
		end

		def close
			@node.content.delete callback
		end
	end

	class CallbackNode < Tree::TreeNode
		def initialize(type)
			super(type, [])
		end

		def register(callback)
			content << callback
		end

		def callers?
			not content.empty?
		end

		def call(message)
			content.each do |callback|
				callback.call(message)
			end
		end
	end

	def initialize
		@callback_tree = Tree::TreeNode.new(:callback_tree)
	end

	def on(type, topic = nil, &callback)
		node = case type
		when :raw
			branch(:raw)
		when :any
			branch(:raw, :parsed)
		when :default
			unless topic
				branch(:raw, :parsed, :default)
			else
				branch(:raw, :parsed, :default, topic)
			end
		else
			unless topic
				branch(:raw, :parsed, type)
			else
				branch(:raw, :parsed, type, topic)
			end
		end

		#@callback_tree.print_tree
		#p node
		node.register(callback)
		
		return Handle.new(node, callback)
	end

	def <<(raw_message)
		message = raw_message
		type_class = nil
		topic = nil
		node = @callback_tree

		[:raw, :parsed, :object, :topic].each do |type|
			type = case type
			when :object
				type_class
			when :topic
				topic
			else
				type
			end

			# try node by type, default or give up
			node = (node[type] or node[:default] or return)

			# parse message - if :parsed branch exists than we have some callers to find
			if type == :parsed 
				message = Message.load(message) 
				type_class = DataType.data_type(message.data_type)
				topic = message.topic
			end

			if node.callers?
				# cast message to data type if we have parsed message but only if we have callers for it
				message = DataType.from_message(message) if message.instance_of? Message
				node.call(message)
			end
		end
	rescue DataType::DataTypeError::UnknownDataTypeError
		# stop processing if messages data type is not known
	end

	private

	# returns existing or newly created branch for path
	def branch(*path)
		node = @callback_tree 
		path.each do |name|
			node << CallbackNode.new(name) unless node[name]
			node = node[name]
		end
		#@callback_tree.print_tree
		node
	end
end

