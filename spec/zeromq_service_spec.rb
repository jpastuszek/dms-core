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

require_relative 'spec_helper'

describe 'ZeroMQService' do
	let :test_address do
		'ipc:///tmp/dms-core-test'
	end

	subject do
		ZeroMQService
	end

	it 'should provide shared poller' do
		subject.poller.should be_a ZeroMQ::Poller
	end

	describe 'socket creation and access' do
		it 'should allow creating socket via passed block' do
			s = subject.socket(:test) do |zmq|
				zmq.push_bind(test_address)
			end

			s.should_not be_nil
			s.should be_a ZeroMQ::Pusher
			s.should_not be_closed

			s.close
			s.should be_closed
		end

		it 'should allow accessing socket via its name' do
			subject.socket(:test2) do |zmq|
				zmq.push_bind(test_address)
			end

			s = subject.socket(:test2)
			s.should_not be_nil
			s.should be_a ZeroMQ::Pusher
			s.should_not be_closed

			s.close
			s.should be_closed
		end

		it 'should allow opening socket under same name' do
			subject.socket(:test3) do |zmq|
				zmq.push_bind(test_address)
			end

			s = subject.socket(:test3)
			s.should_not be_nil
			s.should be_a ZeroMQ::Pusher
			s.should_not be_closed

			s.close
			s.should be_closed

			s = subject.socket(:test3) do |zmq|
				zmq.push_bind(test_address)
			end
			s.should_not be_nil
			s.should_not be_closed

			s.close
			s.should be_closed
		end
	end
end

