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

	describe "on object type" do
		it 'should pass only objects on given type' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_messages = []
			recv_messages_a = []
			recv_messages_b = []

			subject.on(TestMessage) do |message|
				recv_messages << message
			end

			subject.on(TestMessageA) do |message|
				recv_messages_a << message
			end

			subject.on(TestMessageB) do |message|
				recv_messages_b << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages.select{|m| m.instance_of? TestMessage}
			recv_messages_a.should == sent_messages.select{|m| m.instance_of? TestMessageA}
			recv_messages_b.should == sent_messages.select{|m| m.instance_of? TestMessageB}
		end

		it 'should pass objects to multiple callbacks' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_messages = []
			recv_messages_a = []
			recv_messages_a2 = []
			recv_messages_b = []
			recv_messages_b2 = []
			recv_messages_b3 = []

			subject.on(TestMessage) do |message|
				recv_messages << message
			end

			subject.on(TestMessageA) do |message|
				recv_messages_a << message
			end

			subject.on(TestMessageA) do |message|
				recv_messages_a2 << message
			end

			subject.on(TestMessageB) do |message|
				recv_messages_b << message
			end

			subject.on(TestMessageB) do |message|
				recv_messages_b2 << message
			end

			subject.on(TestMessageB) do |message|
				recv_messages_b3 << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages.select{|m| m.instance_of? TestMessage}
			recv_messages_a.should == sent_messages.select{|m| m.instance_of? TestMessageA}
			recv_messages_a2.should == sent_messages.select{|m| m.instance_of? TestMessageA}
			recv_messages_b.should == sent_messages.select{|m| m.instance_of? TestMessageB}
			recv_messages_b2.should == sent_messages.select{|m| m.instance_of? TestMessageB}
			recv_messages_b3.should == sent_messages.select{|m| m.instance_of? TestMessageB}
		end

		it 'should pass object to :any handler first' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_order = []
			recv_messages_any = []
			recv_messages = []

			subject.on(:any) do |message|
				recv_messages_any << message
				recv_order << 'any'
			end

			subject.on(TestMessage) do |message|
				recv_messages << message
				recv_order << 'object'
			end

			subject.on(TestMessageA) do |message|
				recv_messages << message
				recv_order << 'object'
			end

			subject.on(TestMessageB) do |message|
				recv_messages << message
				recv_order << 'object'
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages
			recv_order.should == [
				'any', 'object',
				'any', 'object',
				'any', 'object',
				'any', 'object',
				'any', 'object',
			]

		end
	end
end

