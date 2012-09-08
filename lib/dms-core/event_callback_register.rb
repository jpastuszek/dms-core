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
		@callback_tree = Tree::TreeNode.new(:root)
	end

	def on(type, topic = nil, &callback)
		node = case type
		when :raw
			branch(:raw)
		when :any
			branch(:raw, :parsed)
		when :default
			branch(:raw, :parsed, :default)
		else
			fail
		end

		#@callback_tree.print_tree
		#p node
		node.register(callback)
		
		return Handle.new(node, callback)
	end

	def <<(raw_message)
		message = raw_message
		node = @callback_tree

		[:raw, :parsed, :default].each do |type|
			# quit if we don't have more branches
			node = node[type] or return

			# parse message - if :parsed branch exists than we have some callers to find
			message = Message.load(message) if type == :parsed 

			if node.callers?
				# cast message to data type if we have parsed message but only if we have callers for it
				message = DataType.from_message(message) if message.instance_of? Message
				node.call(message)
			end
		end
	end

	private

	# returns existing or newly created branch for path
	def branch(*path)
		node = @callback_tree 
		path.each do |name|
			if name.is_a? Symbol
				node << CallbackNode.new(name) unless node[name]
				node = node[name]
			else
				fail "not impl"
			end
		end
		node
	end
end

