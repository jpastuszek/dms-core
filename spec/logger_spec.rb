require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "logging" do
	it "should log to STDERR by default with #log method" do
		out = stderr_read do
			log.debug "this is a debug"
			log.info "this is a info"
			log.warn "this is a warn"
			log.error "this is a error"
		end

		out.should include("this is a debug")
		out.should include("this is a info")
		out.should include("this is a warn")
		out.should include("this is a error")
	end
end

