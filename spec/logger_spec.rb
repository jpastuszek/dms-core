require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Kernel#log' do
	it "should by default log to STDERR at INFO level" do
		out = Capture.stderr do
			log.debug "this is a debug"
			log.info "this is a info"
			log.warn "this is a warn"
			log.error "this is a error"
		end

		out.should_not include("this is a debug")
		out.should include("this is a info")
		out.should include("this is a warn")
		out.should include("this is a error")
	end

	it "should log class names" do
		class TestA
			def initialize
				log.info "this is a test A"
			end
		end

		class TestB
			def initialize
				log.info "this is a test B"
			end
		end

		out = Capture.stderr do
			TestA.new
			TestB.new
		end

		out.should include("TestA")
		out.should include("TestB")
	end

	it "should allow specifing custom class name" do
		class TestA
			def initialize
				logging_class_name 'HelloWorld'
				log.info "this is a test A"
			end
		end

		out = Capture.stderr do
			TestA.new
		end

		out.should include("HelloWorld")
	end

	it "should allow specifing custom logging context" do
		class TestA
			def initialize
				logging_context 'hello world'
				log.info "this is a test A"
			end
		end

		out = Capture.stderr do
			TestA.new
		end

		out.should include("TestA[hello world]")
	end
end

