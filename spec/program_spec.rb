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

shared_examples :program do
	it 'should provide --version' do
		Capture.stdout do
			Capture.stderr do
				expect {
					subject.new('DMS Test Daemon', version, ['--version']) do
						main do |s|
						end
					end
				}.to raise_error SystemExit
			end
		end.should include 'version "0.0.0"'
	end

	it 'should log startup errors' do
		Capture.stderr do
			expect {
				subject.new('DMS Test Daemon', version) do
					main do |s|
						raise 'test'
					end
				end
			}.to raise_error SystemExit
		end.should include 'got error: RuntimeError: test'
	end

	it 'exit with 2 on startup errors' do
		Capture.stderr do
			expect {
				subject.new('DMS Test Daemon', version) do
					main do |s|
						raise 'test'
					end
				end
			}.to raise_error { |error| 
				error.should be_a SystemExit
				error.status.should == 2
			}
		end
	end

	it 'should allow validation of settings' do
		Capture.stderr do
			expect {
				subject.new('DMS Test Daemon', version) do
					validate do |settings|
						raise 'test'
					end
				end
			}.to raise_error SystemExit
		end.should include 'Error: test'
	end

	it 'should set up logging' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version, ['-d']) do
				main do |s|
					settings = s
				end
			end
		end

		settings.debug.should be_true
		Logging.logger.root.level.should == 0
	end

	it 'should provide program name in settings' do
		settings = nil
		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				main do |s|
					settings = s
				end
			end
		end

		settings.program_name.should == 'DMS Test Daemon'
	end

	it 'should provide short program name in settings' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version, ['-d']) do
				main do |s|
					settings = s
				end
			end
		end

		settings.program.should == 'dms-test-daemon'
	end

	it 'should provide pid in settings' do
		settings = nil
		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				main do |s|
					settings = s
				end
			end
		end

		settings.pid.should be_a Integer
	end

	it 'should provide host name in settings' do
		settings = nil
		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				main do |s|
					settings = s
				end
			end
		end

		settings.host_name.should == Facter.fqdn
	end
	
	it 'should provide unique program idetifier in settings' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version, ['-d']) do
				main do |s|
					settings = s
				end
			end
		end

		settings.program_id.should == "dms-test-daemon:#{Facter.fqdn}:#{Process.pid}"
	end

	it 'should provide version in settings' do
		settings = nil
		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				main do |s|
					settings = s
				end
			end
		end

		settings.version.should =~ /^\d+\.\d+\.\d+$/
	end

	it 'should provide zeromq versions in settings' do
		settings = nil
		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				main do |s|
					settings = s
				end
			end
		end

		settings.libzmq_version.should =~ /^\d+\.\d+\.\d+$/
		settings.libzmq_binding_version.should =~ /^\d+\.\d+\.\d+$/
	end

	it 'should have console_connection cli generator' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
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

	it 'should have internal_console_connection cli generator' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				cli do
					internal_console_connection
				end
				
				main do |s|
					settings = s
				end
			end
		end

		settings.internal_console_subscriber.should == 'ipc:///tmp/dms-console-connector-sub'
		settings.internal_console_publisher.should == 'ipc:///tmp/dms-console-connector-pub'
	end

	it 'should parse given cli arguments' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version, ['--hello', 'world']) do
				cli do
					option :hello
				end
				
				main do |s|
					settings = s
				end
			end
		end

		settings.hello.should == 'world'
	end

	it 'should parse cli arguments from DMS_PROGRAM_ARGS environment variable' do
		settings = nil

		ENV['DMS_PROGRAM_ARGS'] = '--hello world'

		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				cli do
					option :hello
				end
				
				main do |s|
					settings = s
				end
			end
		end

		ENV['DMS_PROGRAM_ARGS'] = nil

		settings.hello.should == 'world'
	end

	it 'should have linger_time cli generator' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				cli do
					linger_time
				end
				
				main do |s|
					settings = s
				end
			end
		end

		settings.linger_time.should == 10
	end

	it 'should have hello_wait cli generator' do
		settings = nil

		Capture.stderr do
			subject.new('DMS Test Daemon', version) do
				cli do
					hello_wait
				end
				
				main do |s|
					settings = s
				end
			end
		end

		settings.hello_wait.should == 4
	end
end

describe Program do
	let :version do
		'0.0.0'
	end

	before :each do
		# reset logging
		Logging.logger.root.level = :info
		Logging.logger.root.appenders = Logging.appenders.stderr(:layout => Logging::Layouts::Pattern.new)
	end

	describe Program::Tool do
		subject do
			Program::Tool
		end

		it 'should log in simplified format' do
			Capture.stderr do
				subject.new('DMS Test Daemon', version) do
					main do |s|
						log.info 'test'
					end
				end
			end.should =~ /\d+-\d+-\d+ \d+:\d+:\d+ - test/
		end
		
		it 'should log program name, version, zeromq version and pid only on debug level' do
			Capture.stderr do
				subject.new('DMS Test Tool', version) do
				end
			end.should_not =~ /DMS Test Tool version \d+\.\d+\.\d+ \(LibZMQ version \d+\.\d+\.\d+, ffi-ruby version \d+\.\d+\.\d+\); pid \d+/

			Capture.stderr do
				subject.new('DMS Test Tool', version, ['-d']) do
				end
			end.should =~ /DMS Test Tool version \d+\.\d+\.\d+ \(LibZMQ version \d+\.\d+\.\d+, ffi-ruby version \d+\.\d+\.\d+\); pid \d+/
		end

		it_behaves_like :program
	end

	describe Program::Daemon do
		subject do
			Program::Daemon
		end
		
		it 'should set logging class name to match program name' do
			Capture.stderr do
				subject.new('DMS Test Daemon', version) do
					main do |s|
						log.info 'test'
					end
				end
			end.should include 'DMSTestDaemon : test'
		end

		it 'should log program name, version, zeromq version ' do
			Capture.stderr do
				subject.new('DMS Test Daemon', version) do
				end
			end.should =~ /Starting DMS Test Daemon version \d+\.\d+\.\d+ \(LibZMQ version \d+\.\d+\.\d+, ffi-ruby version \d+\.\d+\.\d+\); pid \d+/
		end

		it 'should log program name done at exit' do
			Capture.stderr do
				subject.new('DMS Test Daemon', version) do
					main do |s|
					end
				end
			end.should include 'DMS Test Daemon done'
		end

		it 'should log program name done on error' do
			Capture.stderr do
				expect {
					subject.new('DMS Test Daemon', version) do
						main do |s|
							raise
						end
					end
				}.to raise_error SystemExit
			end.should include 'DMS Test Daemon done'
		end

		it_behaves_like :program

		describe '#main_loop' do
			it 'should log ready on #main_loop' do
				Capture.stderr do
					subject.new('DMS Test Daemon', version) do
						main do |s|
						end
					end
				end.should_not include 'ready'

				Capture.stderr do
					subject.new('DMS Test Daemon', version) do
						main do |s|
							main_loop do
							end
						end
					end
				end.should include 'ready'
			end

			it 'should capture exceptions and log them' do
				Capture.stderr do
					expect {
						subject.new('DMS Test Daemon', version) do
							main do |s|
								main_loop do
									raise 'test'
								end
							end
						end
					}.to raise_error SystemExit
				end.should include 'got error: RuntimeError: test'
			end

			it 'exit with 3 on startup errors' do
				Capture.stderr do
					expect {
						subject.new('DMS Test Daemon', version) do
							main do |s|
								main_loop do
									raise 'test'
								end
							end
						end
					}.to raise_error { |error| 
						error.should be_a SystemExit
						error.status.should == 3
					}
				end
			end
		end
	end
end

