require 'logger'

module Kernel
	def log
		@logger ||= Logger.new(STDERR)
	end
end

