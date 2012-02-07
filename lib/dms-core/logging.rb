require 'logging'

Logging.logger.root.appenders = Logging.appenders.stderr(:layout => Logging::Layouts::Pattern.new)
Logging.logger.root.level = :info

module Kernel
	def log
		class_name = @logging_class_name ? @logging_class_name : self.class.name

		if @logging_context
			class_name += '[' + @logging_context.to_s + ']'
		end

		Logging.logger[class_name]
	end

	def logging_class_name(string)
		@logging_class_name = string
	end

	def logging_context(string)
		@logging_context = string
	end
end

