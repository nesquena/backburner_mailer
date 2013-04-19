# BackburnerMailer

A gem plugin which allows messages prepared by ActionMailer or Padrino Mailer to be delivered
asynchronously. Assumes you're using Backburner (http://github.com/nesquena/backburner)
for your background jobs.

Note that Backburner::Mailer only works with Rails 3.x and Padrino.

This was **heavily** inspired by and largely adapted from [resque-mailer](https://github.com/zapnap/resque_mailer).
Most of the credit goes to them, this is a minor adaptation to support backburner.

## Usage

Include Backburner::Mailer in your ActionMailer subclass(es) like this:

    class MyMailer < ActionMailer::Base
      include Backburner::Mailer
    end

Now, when `MyMailer.subject_email(params).deliver` is called, an entry
will be created in the job queue. Your Backburner workers will be able to deliver
this message for you. The queue we're using is named +mailer+,
so just make sure your workers know about it and are loading your environment:

    QUEUE=mailer bundle exec rake backburner:work

Note that you can still have mail delivered synchronously by using the bang
method variant:

    MyMailer.subject_email(params).deliver!

Oh, by the way. Don't forget that **your async mailer jobs will be processed by
a separate worker**. This means that you should resist the temptation to pass
database-backed objects as parameters in your mailer and instead pass record
identifiers. Then, in your delivery method, you can look up the record from
the id and use it as needed.

If you want to set a different default queue name for your mailer, you can
change the `default_queue_name` property like so:

    # config/initializers/backburner_mailer.rb
    Backburner::Mailer.default_queue_name = 'application_specific_mailer'

This is useful when you are running more than one application using
backburner_mailer in a shared environment. You will need to use the new queue
name when starting your workers.

    QUEUE=application_specific_mailer bundle exec rake backburner:work

Custom handling of errors that arise when sending a message is possible by
assigning a lambda to the `error_hander` attribute.

```ruby
Backburner::Mailer.error_handler = lambda { |mailer, message, error|
  # some custom error handling code here in which you optionally re-raise the error
}
```

## Installation

Install the gem:

    gem install backburner_mailer

If you're using Bundler to manage your dependencies, you should add it to your Gemfile:

    gem 'backburner'
    gem 'backburner_mailer'

## Testing

You don't want to be sending actual emails in the test environment, so you can
configure the environments that should be excluded like so:

    # config/initializers/backburner_mailer.rb
    Backburner::Mailer.excluded_environments = [:test, :cucumber]

Note: Define `current_env` if using Backburner::Mailer in a non-Rails or non-Padrino project:

    Backburner::Mailer.current_env = :production

## Note on Patches / Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Credits

Developed by Nathan Esquenazi.
Shamelessly adapted from [resque-mailer](https://github.com/zapnap/resque_mailer).
Code originally developed by Nick Plante with help from a number of [contributors](https://github.com/zapnap/resque_mailer/contributors).