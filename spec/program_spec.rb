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

describe Program do
	describe Program::Daemon do
		it 'should log program name, version, zeromq version and pid and provide this values in settings' do
			settings = nil
			Program::Daemon.new('DMS Test Daemon') do
				main do |s|
					settings = s
				end
			end

			p settings
		end

		it 'should set up logging' do
			settings = nil
			Logging.logger.root.level.should == 1

			Program::Daemon.new('DMS Test Daemon', ['-d']) do
				main do |s|
					settings = s
				end
			end

			settings.debug.should be_true
			Logging.logger.root.level.should == 0
		end

		it 'should have console_connection cli generator' do
			settings = nil

			Program::Daemon.new('DMS Test Daemon') do
				cli do
					console_connection
				end
				
				main do |s|
					settings = s
				end
			end

			settings.console_subscriber.should == 'tcp://127.0.0.1:12000'
			settings.console_publisher.should == 'tcp://127.0.0.1:12001'
		end
	end
end

