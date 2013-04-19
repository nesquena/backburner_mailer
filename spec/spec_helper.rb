$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'action_mailer'
require 'backburner_mailer'
require 'rspec/autorun'

Backburner::Mailer.excluded_environments = []
ActionMailer::Base.delivery_method = :test
