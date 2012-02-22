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

describe DSL do
	describe 'variable support' do
		it 'when used without block instance variables are set to defaults' do
			test = Class.new do
				include DSL
				def initialize(&block)
					dsl_variable :test, 123
					dsl_variable :xyz
					dsl &block
				end
				attr_reader :test, :xyz
			end

			t = test.new
			t.test.should == 123
			t.xyz.should == nil
		end 

		it 'when used whit block instance variables are set to values from DSL' do
			test = Class.new do
				include DSL
				def initialize(&block)
					dsl_variable :test, 123
					dsl_variable :xyz
					dsl &block
				end
				attr_reader :test, :xyz
			end

			t = test.new do
				xyz 'hello world'
			end

			t.test.should == 123
			t.xyz.should == 'hello world'
		end 
	end

	describe 'varaible array support' do
		it 'when used without block instance variables are set to defaults' do
			test = Class.new do
				include DSL
				def initialize(&block)
					dsl_variables :test, [1, 2, 3]
					dsl_variables :abc, 99
					dsl_variables :xyz
					dsl &block
				end
				attr_reader :test, :abc, :xyz
			end

			t = test.new
			t.test.should == [1, 2, 3]
			t.abc.should == [99]
			t.xyz.should == []
		end 

		it 'when used whit block instance variables are set to values from DSL' do
			test = Class.new do
				include DSL
				def initialize(&block)
					dsl_variables :test, [1, 2, 3]
					dsl_variables :abc, 99
					dsl_variables :xyz
					dsl &block
				end
				attr_reader :test, :abc, :xyz
			end

			t = test.new do
				abc 'hello'
				abc 'world'
				xyz true
			end

			t.test.should == [1, 2, 3]
			t.abc.should == [99, 'hello', 'world']
			t.xyz.should == [true]
		end 
	end

	it 'should allow defining custom handlers' do
		test = Class.new do
			include DSL
			def initialize(&block)
				@test = []

				dsl_method :test do |v1|
					@test << v1
				end

				dsl &block
			end
			attr_reader :test
		end

		t = test.new do
			test 'hello'
			test 'world'
		end

		t.test.should == ['hello', 'world']
	end

	it 'should raise error on undefined method call' do
		DSLTest = Class.new do
			include DSL
			def initialize(&block)
				dsl_variable :xyz
				dsl &block
			end
			attr_reader :test, :xyz
		end

		expect {
			DSLTest.new do
				xyz 'hello world'
				abc 1
			end
		}.to raise_error(NoMethodError, "undefined method `abc' for DSLTest:DSL::Env")
	end

	it 'should allow to specify name for DSL object inspect' do
		test = Class.new do
			include DSL
			def initialize(&block)
				dsl_variable :xyz
				dsl 'Hello World DSL', &block
			end
			attr_reader :test, :xyz
		end

		expect {
			test.new do
				xyz 'hello world'
				abc 1
			end
		}.to raise_error(NoMethodError, "undefined method `abc' for Hello World DSL:DSL::Env")
	end
end

