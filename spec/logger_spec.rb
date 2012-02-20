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

