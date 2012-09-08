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
require 'dms-core/event_callback_register'

describe EventCallbackRegister do
	describe 'on :raw' do
		it 'should pass all messages in raw form' do
			messages = []

			subject.on(:raw) do |message|
				messages << message
			end

			subject << 'm1'
			subject << 'm2'

			messages.should == ['m1', 'm2']
		end
	end

	describe 'on :any' do
		it 'should pass all messages in parsed form' do
			sent_messages = [TestMessage.new(1), TestMessage.new(2)]
			recv_messages = []

			subject.on(:any) do |message|
				recv_messages << message
			end

			sent_messages.each do |message|
				subject << message.to_message.to_s
			end

			recv_messages.should == sent_messages
		end

		it 'should pass all messages in raw form for :raw callback' do
			sent_messages = [TestMessage.new(1), TestMessage.new(2)]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_raw_messages = []
			recv_messages = []

			subject.on(:raw) do |message|
				recv_raw_messages << message
			end

			subject.on(:any) do |message|
				recv_messages << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_raw_messages.should == sent_raw_messages
			recv_messages.should == sent_messages
		end
	end
end

