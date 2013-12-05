require "backburner_mailer/version"
require "backburner"

module Backburner
  module Mailer
    class << self
      attr_accessor :default_queue_name, :default_queue_target, :current_env, :logger, :fallback_to_synchronous, :error_handler
      attr_reader :excluded_environments

      def excluded_environments=(envs)
        @excluded_environments = [*envs].map { |e| e.to_sym }
      end

      def included(base)
        base.send(:include, Backburner::Queue)
        base.extend(ClassMethods)
      end
    end

    self.logger = nil
    self.default_queue_target = ::Backburner::Worker
    self.default_queue_name = "mailer"
    self.excluded_environments = []

    module ClassMethods

      def current_env
        if defined?(Rails)
          ::Backburner::Mailer.current_env || ::Rails.env
        elsif defined?(Padrino)
          ::Backburner::Mailer.current_env || ::Padrino.env
        else
          ::Backburner::Mailer.current_env
        end
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          MessageDecoy.new(self, method_name, *args)
        else
          super
        end
      end

      def perform(action, *args)
        begin
          message = self.send(:new, action, *args).message
          message.deliver
        rescue Exception => ex
          if Mailer.error_handler
            Mailer.error_handler.call(self, message, ex)
          else
            if logger
              logger.error "Unable to deliver email [#{action}]: #{ex}"
              logger.error ex.backtrace.join("\n\t")
            end
            raise ex
          end
        end
      end

      def queue
        @queue || ::Backburner::Mailer.default_queue_name
      end

      def queue=(name)
        @queue = name
      end

      def backburner
        ::Backburner::Mailer.default_queue_target
      end

      def excluded_environment?(name)
        ::Backburner::Mailer.excluded_environments && ::Backburner::Mailer.excluded_environments.include?(name.try(:to_sym))
      end

      def deliver?
        true
      end
    end

    class MessageDecoy
      delegate :to_s, :to => :actual_message

      def initialize(mailer_class, method_name, *args)
        @mailer_class = mailer_class
        @method_name = method_name
        *@args = *args
      end

      def backburner
        ::Backburner::Mailer.default_queue_target
      end

      def current_env
        if defined?(Rails)
          ::Backburner::Mailer.current_env || ::Rails.env
        elsif defined?(Padrino)
          ::Backburner::Mailer.current_env || ::Padrino.env
        else
          ::Backburner::Mailer.current_env
        end
      end

      def environment_excluded?
        !ActionMailer::Base.perform_deliveries || excluded_environment?(current_env)
      end

      def excluded_environment?(name)
        ::Backburner::Mailer.excluded_environments && ::Backburner::Mailer.excluded_environments.include?(name.to_sym)
      end

      def actual_message
        @actual_message ||= @mailer_class.send(:new, @method_name, *@args).message
      end

      def deliver(opts = {})
        return deliver! if environment_excluded?

        if @mailer_class.deliver?
          begin
            backburner.enqueue(@mailer_class, [@method_name].concat(@args), opts)
          rescue Errno::ECONNREFUSED
            deliver!
          end
        end
      end

      def deliver!
        actual_message.deliver
      end

      def method_missing(method_name, *args)
        actual_message.send(method_name, *args)
      end
    end
  end
end
