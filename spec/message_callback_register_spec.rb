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
require 'dms-core/message_callback_register'

describe MessageCallbackRegister do
	describe 'on :raw' do
		it 'should pass all messages in raw form without looking into them' do
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
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}
			recv_messages = []

			subject.on(:any) do |message|
				recv_messages << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages
		end

		it 'should not process messages of unknown type' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageUnregistered.new(4),
				TestMessage.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_messages = []

			subject.on(:any) do |message|
				recv_messages << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages.select{|m| not m.instance_of? TestMessageUnregistered}
		end

		it 'should pass messages to :raw callback first' do
			sent_messages = [TestMessage.new(1), TestMessage.new(2)]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_order = []
			recv_raw_messages = []
			recv_messages = []

			subject.on(:any) do |message|
				recv_messages << message
				recv_order << :any
			end

			subject.on(:raw) do |message|
				recv_raw_messages << message
				recv_order << :raw
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages
			recv_raw_messages.should == sent_raw_messages
			recv_order.should == [
				:raw, :any,
				:raw, :any,
			]
		end
	end

	describe "on message type" do
		it 'should pass only messages of given type' do
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

		it 'should pass messages to multiple callbacks' do
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

		it 'should pass message to :any callback first' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_order = []
			recv_any_messages = []
			recv_messages = []

			subject.on(TestMessage) do |message|
				recv_messages << message
				recv_order << message.class
			end

			subject.on(TestMessageA) do |message|
				recv_messages << message
				recv_order << message.class
			end

			subject.on(TestMessageB) do |message|
				recv_messages << message
				recv_order << message.class
			end

			subject.on(:any) do |message|
				recv_any_messages << message
				recv_order << :any
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages
			recv_any_messages.should == sent_messages
			recv_order.should == [
				:any, TestMessage,
				:any, TestMessageA,
				:any, TestMessageB,
				:any, TestMessageA,
				:any, TestMessageB,
			]
		end
	end
	
	describe 'on :default' do
		it 'should pass only objects that does not match any callback for data type' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_messages = []
			recv_messages_default = []

			subject.on(TestMessage) do |message|
				recv_messages << message
			end

			subject.on(:default) do |message|
				recv_messages_default << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages.select{|m| m.instance_of? TestMessage}
			recv_messages_default.should == sent_messages.select{|m| m.instance_of? TestMessageA or m.instance_of? TestMessageB}
		end

		it 'should pass message to :any callback first' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(4),
				TestMessageB.new(5),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message.to_s}

			recv_order = []
			recv_any_messages = []
			recv_messages = []

			subject.on(:default) do |message|
				recv_messages << message
				recv_order << message.class
			end

			subject.on(:any) do |message|
				recv_any_messages << message
				recv_order << :any
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == sent_messages
			recv_any_messages.should == sent_messages
			recv_order.should == [
				:any, TestMessage,
				:any, TestMessageA,
				:any, TestMessageB,
				:any, TestMessageA,
				:any, TestMessageB,
			]
		end
	end

	describe "on message type + topic" do
		it 'should pass only messages of given type and for given topic' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(3),
				TestMessageB.new(4),
				TestMessageB.new(4),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message('topic'+ msg.value.to_s).to_s}

			recv_messages_a = []
			recv_messages_a_2 = []
			recv_messages_a_3 = []
			recv_messages_b_3 = []
			recv_messages_b_4 = []

			subject.on(TestMessageA) do |message|
				recv_messages_a << message
			end

			subject.on(TestMessageA, 'topic2') do |message|
				recv_messages_a_2 << message
			end

			subject.on(TestMessageA, 'topic3') do |message|
				recv_messages_a_3 << message
			end

			subject.on(TestMessageB, 'topic3') do |message|
				recv_messages_b_3 << message
			end

			subject.on(TestMessageB, 'topic4') do |message|
				recv_messages_b_4 << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages_a.should == sent_messages.select{|m| m.instance_of? TestMessageA}

			recv_messages_a_2.should == [TestMessageA.new(2)]
			recv_messages_a_3.should == [TestMessageA.new(3)]
			recv_messages_b_3.should == [TestMessageB.new(3)]
			recv_messages_b_4.should == [TestMessageB.new(4), TestMessageB.new(4)]
		end

		it 'should pass message to message type callback first' do
			sent_messages = [
				TestMessageA.new(1),
				TestMessageA.new(2),
				TestMessageA.new(1),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message('topic'+ msg.value.to_s).to_s}

			recv_order = []
			recv_type_messages = []
			recv_messages = []

			subject.on(TestMessageA, 'topic1') do |message|
				recv_messages << message
				recv_order << :topic
			end

			subject.on(TestMessageA) do |message|
				recv_type_messages << message
				recv_order << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages.should == [TestMessageA.new(1), TestMessageA.new(1)]
			recv_type_messages.should == sent_messages
			recv_order.should == [
				TestMessageA.new(1), :topic,
				TestMessageA.new(2),
				TestMessageA.new(1), :topic,
			]
		end
	end

	describe "on :default + topic" do
		it 'should pass only objects that does not match any callback for data type but for given topic' do
			sent_messages = [
				TestMessage.new(1), 
				TestMessageA.new(2),
				TestMessageB.new(3),
				TestMessageA.new(3),
				TestMessageB.new(4),
				TestMessageB.new(4),
			]
			sent_raw_messages = sent_messages.map{|msg| msg.to_message('topic'+ msg.value.to_s).to_s}

			recv_messages_default_2 = []
			recv_messages_default_3 = []
			recv_messages_b_3 = []
			recv_messages_b_4 = []

			subject.on(:default, 'topic2') do |message|
				recv_messages_default_2 << message
			end

			subject.on(:default, 'topic3') do |message|
				recv_messages_default_3 << message
			end

			subject.on(TestMessageB, 'topic3') do |message|
				recv_messages_b_3 << message
			end

			subject.on(TestMessageB, 'topic4') do |message|
				recv_messages_b_4 << message
			end

			sent_raw_messages.each do |message|
				subject << message
			end

			recv_messages_default_2.should == [TestMessageA.new(2)]
			recv_messages_default_3.should == [TestMessageA.new(3)]
			recv_messages_b_3.should == [TestMessageB.new(3)]
			recv_messages_b_4.should == [TestMessageB.new(4), TestMessageB.new(4)]
		end
	end
end

describe MessageCallbackRegister::MessageCallback do
	subject do
		MessageCallbackRegister::MessageCallback
	end

	it 'should be returned by every on call' do
		MessageCallbackRegister.new.on(:raw){}.should be_instance_of subject
		MessageCallbackRegister.new.on(:any){}.should be_instance_of subject
		MessageCallbackRegister.new.on(:default){}.should be_instance_of subject
		MessageCallbackRegister.new.on(TestMessage){}.should be_instance_of subject
		MessageCallbackRegister.new.on(TestMessage, 'topic2'){}.should be_instance_of subject
		MessageCallbackRegister.new.on(:default, 'topic2'){}.should be_instance_of subject
	end

	it 'should allow deregistration of the callback via #close' do
		sent_messages = [
			TestMessage.new(1), 
			TestMessageA.new(2),
			TestMessageB.new(3),
			TestMessageA.new(3),
			TestMessageB.new(4),
			TestMessageB.new(4),
		]
		sent_raw_messages = sent_messages.map{|msg| msg.to_message('topic'+ msg.value.to_s).to_s}
		message_callback_register = MessageCallbackRegister.new

		recv_raw_messages = []
		recv_any_messages = []
		recv_default1_messages = []
		recv_default2_messages = []

		on_raw = message_callback_register.on(:raw) do |message|
			recv_raw_messages << message
		end 

		on_any = message_callback_register.on(:any) do |message| 
			recv_any_messages << message
		end

		on_default1 = message_callback_register.on(:default) do |message|
			recv_default1_messages << message
		end

		on_default2 = message_callback_register.on(:default) do |message|
			recv_default2_messages << message
		end

		raw_messages = sent_raw_messages.dup

		message_callback_register << raw_messages.shift
		message_callback_register << raw_messages.shift

		recv_raw_messages.should == sent_raw_messages.take(2)
		recv_any_messages.should == sent_messages.take(2)
		recv_default1_messages.should == sent_messages.take(2)
		recv_default2_messages.should == sent_messages.take(2)

		on_any.close

		message_callback_register << raw_messages.shift
		recv_raw_messages.should == sent_raw_messages.take(3)
		recv_any_messages.should == sent_messages.take(2)
		recv_default1_messages.should == sent_messages.take(3)
		recv_default2_messages.should == sent_messages.take(3)

		on_default1.close

		message_callback_register << raw_messages.shift
		recv_raw_messages.should == sent_raw_messages.take(4)
		recv_any_messages.should == sent_messages.take(2)
		recv_default1_messages.should == sent_messages.take(3)
		recv_default2_messages.should == sent_messages.take(4)

		on_default2.close

		message_callback_register << raw_messages.shift
		recv_raw_messages.should == sent_raw_messages.take(5)
		recv_any_messages.should == sent_messages.take(2)
		recv_default1_messages.should == sent_messages.take(3)
		recv_default2_messages.should == sent_messages.take(4)

		on_raw.close

		message_callback_register << raw_messages.shift
		recv_raw_messages.should == sent_raw_messages.take(5)
		recv_any_messages.should == sent_messages.take(2)
		recv_default1_messages.should == sent_messages.take(3)
		recv_default2_messages.should == sent_messages.take(4)
	end
end

