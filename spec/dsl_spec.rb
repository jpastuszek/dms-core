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

	describe 'custom method handler' do
		it 'when used in DSL should call a block with parameters' do
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

		it 'should allow passing a block' do
			test = Class.new do
				include DSL
				def initialize(&block)
					@test = []

					dsl_method :test do |v1, &block|
						@test << v1
						@test << block.call
					end

					dsl &block
				end
				attr_reader :test
			end

			t = test.new do
				test('hello'){'world'}
			end

			t.test.should == ['hello', 'world']
		end

		it 'should pass block return value to DSL to allow chaining' do
			test = Class.new do
				include DSL
				def initialize(&block)
					@test = []

					dsl_method :test do |v1, &block|
						@test << v1
						@test << block.call
						42
					end

					dsl &block
				end
				attr_reader :test
			end

			t = test.new do
				test('hello'){'world'}.should == 42
			end
		end
	end

	describe 'nested DSL objects' do
		it 'should allow to nesting DSL objects' do
			class1 = Class.new do
				include DSL

				def initialize(&block)
					class2 = Class.new do
						include DSL

						def initialize(value, &block)
							@value = value
							dsl_variable :method2
							dsl &block
						end
						attr_reader :value, :method2
					end

					@test = []

					dsl_nest :method1, class2 do |object2|
						@test << object2
					end

					dsl &block
				end
				attr_reader :test
			end

			t = class1.new do
				method1('hello') do
					method2('world')
				end
			end

			t.test.should have(1).object

			object = t.test.shift
			object.value.should == 'hello'
			object.method2.should == 'world'
		end
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

	it 'should allow passing arguments to DSL block' do
		test = Class.new do
			include DSL
			def initialize(&block)
				dsl_variable :xyz
				dsl 'hello', 'world', &block
			end
			attr_reader :test, :xyz
		end

		test.new do |hello, world|
			xyz hello + ' ' + world
		end.xyz.should == 'hello world'
	end
end

