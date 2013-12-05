require 'spec_helper'

class FakeBackburner
  def self.enqueue(*args); end
end

class Rails3Mailer < ActionMailer::Base
  include Backburner::Mailer
  default :from => "from@example.org", :subject => "Subject", :body => "Body"
  MAIL_PARAMS = { :to => "crafty@example.org" }

  def test_mail(*params)
    Backburner::Mailer.success!
    mail(*params)
  end
end

class PriorityMailer < Rails3Mailer
  self.queue = 'priority_mailer'
end

describe Backburner::Mailer do
  let(:backburner) { FakeBackburner }

  before do
    Backburner::Mailer.default_queue_target = backburner
    Backburner::Mailer.fallback_to_synchronous = false
    Backburner::Mailer.stub(:success!)
    Backburner::Mailer.stub(:current_env => :test)
  end

  describe "backburner" do
    it "allows overriding of the default queue target (for testing)" do
      Backburner::Mailer.default_queue_target = FakeBackburner
      Rails3Mailer.backburner.should == FakeBackburner
    end
  end

  describe "queue" do
    it "defaults to the 'mailer' queue" do
      Rails3Mailer.queue.should == "mailer"
    end

    it "allows overriding of the default queue name" do
      Backburner::Mailer.default_queue_name = "postal"
      Rails3Mailer.queue.should == "postal"
    end

    it "allows overriding of the local queue name" do
      PriorityMailer.queue.should == "priority_mailer"
    end
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
      }
    end

    it 'should not deliver the email synchronously' do
      lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it 'should place the deliver action on the Backburner "mailer" queue' do
      backburner.should_receive(:enqueue).with(Rails3Mailer, [:test_mail, Rails3Mailer::MAIL_PARAMS], {})
      @delivery.call
    end
    
    it 'should send email with after 60 seconds delay using backburner options' do
      backburner.should_receive(:enqueue).with(Rails3Mailer, [:test_mail, Rails3Mailer::MAIL_PARAMS], { :delay => 60 })
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver(:delay => 60)
    end

    context "when current env is excluded" do
      it 'should not deliver through Backburner for excluded environments' do
        Backburner::Mailer.stub(:excluded_environments => [:custom])
        Backburner::Mailer::MessageDecoy.any_instance.should_receive(:current_env).and_return(:custom)
        backburner.should_not_receive(:enqueue)
        @delivery.call
      end
    end

    it 'should not invoke the method body more than once' do
      Backburner::Mailer.should_not_receive(:success!)
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
    end

    context "when fallback_to_synchronous is true" do
      before do
        Backburner::Mailer.fallback_to_synchronous = true
      end

      context "when redis is not available" do
        before do
          Backburner::Mailer.default_queue_target.stub(:enqueue).and_raise(Errno::ECONNREFUSED)
        end

        it 'should deliver the email synchronously' do
          lambda { @delivery.call }.should change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver the email synchronously' do
      lambda { Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver! }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe 'perform' do
    it 'should perform a queued mailer job' do
      lambda {
        Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS)
      }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end

    context "when job fails" do
      let(:message) { double(:message) }
      let(:mailer) { double(:mailer, :message => message) }
      let(:logger) { double(:logger, :error => nil) }
      let(:exception) { Exception.new("An error") }

      before(:each) do
        Backburner::Mailer.error_handler = nil
        Rails3Mailer.logger = logger
        Rails3Mailer.stub(:new) { mailer }
        message.stub(:deliver).and_raise(exception)
      end

      subject { Rails3Mailer.perform(:test_mail, Rails3Mailer::MAIL_PARAMS) }

      it "raises and logs the exception" do
        logger.should_receive(:error).at_least(:once)
        expect { subject }.to raise_error
      end

      context "when error_handler set" do
        before(:each) do
          Backburner::Mailer.error_handler = lambda { |mailer, message, exception|
            @mailer = mailer
            @message = message
            @exception = exception
          }
        end

        it "should pass the mailer to the handler" do
          subject
          @mailer.should eq(Rails3Mailer)
        end

        it "should pass the message to the handler" do
          subject
          @message.should eq(message)
        end

        it "should pass the exception to the handler" do
          subject
          @exception.should eq(exception)
        end
      end
    end
  end

  describe 'original mail methods' do
    it 'should be preserved' do
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject.should == 'Subject'
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).from.should include('from@example.org')
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).to.should include('crafty@example.org')
    end

    it 'should require execution of the method body prior to queueing' do
      Backburner::Mailer.should_receive(:success!).once
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject
    end
  end
end
