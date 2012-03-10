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
	let :version do
		'0.0.0'
	end

	describe Program::Daemon do
		it 'should provide --version' do
			out = Capture.stdout do
				Capture.stderr do
					expect {
						Program::Daemon.new('DMS Test Daemon', version, ['--version']) do
							main do |s|
							end
						end
					}.to raise_error SystemExit
				end
			end

			out.should =~ /version "0.0.0"/
		end

		it 'should set logging class name to match program name' do
			out = Capture.stderr do
				Program::Daemon.new('DMS Test Daemon', version) do
					main do |s|
						log.info 'test'
					end
				end
			end

			out.should =~ /DMSTestDaemon : test/
		end

		it 'should log program name, version, zeromq version and pid and provide this values in settings' do
			settings = nil
			out = Capture.stderr do
				Program::Daemon.new('DMS Test Daemon', version) do
					main do |s|
						settings = s
					end
				end
			end

			out.should =~ /Starting DMS Test Daemon version \d+\.\d+\.\d+ \(LibZMQ version \d+\.\d+\.\d+, ffi-ruby version \d+\.\d+\.\d+\); pid \d+/
			settings.program_name.should == 'DMS Test Daemon'
			settings.version.should =~ /^\d+\.\d+\.\d+$/
			settings.libzmq_version.should =~ /^\d+\.\d+\.\d+$/
			settings.libzmq_binding_version.should =~ /^\d+\.\d+\.\d+$/
			settings.pid.should be_a Integer
		end

		it 'should log program name done at exit' do
			out = Capture.stderr do
				Program::Daemon.new('DMS Test Daemon', version) do
					main do |s|
					end
				end
			end

			out.should =~ /DMS Test Daemon done/
		end

		it 'should log program name done on error' do
			out = Capture.stderr do
				expect {
					Program::Daemon.new('DMS Test Daemon', version) do
						main do |s|
							raise
						end
					end
				}.to raise_error RuntimeError
			end

			out.should =~ /DMS Test Daemon done/
		end

		it 'should allow validation of settings' do
			settings = nil
			out = Capture.stderr do
				expect {
					Program::Daemon.new('DMS Test Daemon', version) do
						cli do 
						end

						validate do |settings|
							raise 'test'
						end
					end
				}.to raise_error SystemExit
			end

			out.should =~ /Error: test/
		end

		it 'should set up logging' do
			settings = nil
			Logging.logger.root.level.should == 1

			out = Capture.stderr do
				Program::Daemon.new('DMS Test Daemon', version, ['-d']) do
					main do |s|
						settings = s
					end
				end
			end

			settings.debug.should be_true
			Logging.logger.root.level.should == 0
		end

		it 'should have console_connection cli generator' do
			settings = nil

			out = Capture.stderr do
				Program::Daemon.new('DMS Test Daemon', version) do
					cli do
						console_connection
					end
					
					main do |s|
						settings = s
					end
				end
			end

			settings.console_subscriber.should == 'tcp://127.0.0.1:12000'
			settings.console_publisher.should == 'tcp://127.0.0.1:12001'
		end
	end
end

