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

describe ModuleBase do
	context 'when used as loaded module base class' do
		subject do
			mod = Class.new(ModuleBase) do
				def initialize(name)
					dsl_variable :abc
					super
				end
				attr_reader :abc
			end
			mod
		end

		it 'should have a name' do
			subject.new('test module').name.should == 'test module'
		end

		it 'should eval DSL provided as a block' do
			subject.new('test module') do
				abc 'xyz'
			end.abc.should == 'xyz'
		end

		it 'should load DSL provided as a string' do
			subject.load('test module', 'abc "xyz"').abc.should == 'xyz'
		end
	end
end

describe ModuleLoader do
	context 'when given class based on ModuleBase class' do
		before :all do
			@modules_dir = Pathname.new(Dir.mktmpdir('dms_core_test_moduled.d'))

			(@modules_dir + 'xyz.rb').open('w') do |f|
				f.write 'abc 123'
			end

			(@modules_dir + 'empty.rb').open('w') do |f|
				f.write('')
			end

			(@modules_dir + 'abc.rb').open('w') do |f|
				f.write 'abc 321'
			end
		end

		subject do
			mod = Class.new(ModuleBase) do
				def initialize(name)
					dsl_variable :abc
					super
				end
				attr_reader :abc
			end

			ModuleLoader.new(mod)
		end

		it 'should load module form a file and log that' do
			Capture.stderr do
				subject.load_file(@modules_dir + 'xyz.rb').abc.should == 123
			end.should include("loading module 'xyz' from:")

			Capture.stderr do
				subject.load_file(@modules_dir + 'empty.rb').abc.should == nil
			end.should include("loading module 'empty' from:")

			Capture.stderr do
				subject.load_file(@modules_dir + 'abc.rb').abc.should == 321
			end.should include("loading module 'abc' from:")
		end

		it 'should load directory in alphabetical order and log that' do
			log = Capture.stderr do
				modules = subject.load_directory(@modules_dir)
				modules.shift.abc.should == 321
				modules.shift.abc.should == nil
				modules.shift.abc.should == 123
			end

			log.should include("loading module 'xyz' from:")
			log.should include("loading module 'empty' from:")
			log.should include("loading module 'abc' from:")
		end

		after :all do
			@modules_dir.rmtree
		end
	end
end

