require 'logging'

Logging.logger.root.appenders = Logging.appenders.stderr(:layout => Logging::Layouts::Pattern.new)
Logging.logger.root.level = :info

module Kernel
	def log
		Logging.logger[self]
	end
end

