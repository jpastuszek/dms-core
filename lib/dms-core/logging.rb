require 'logging'

Logging.logger.root.appenders = Logging.appenders.stderr
Logging.logger.root.level = :info

module Kernel
	def log
		Logging.logger[self]
	end
end

