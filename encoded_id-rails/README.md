# EncodedId::Rails

EncodedId mixin for your ActiveRecord models.

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/encoded_id/rails`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
  
  def slug
    full_name.parameterize
  end
end

user = User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
user.encoded_id  # => "p5w9-z27j"
user.slugged_id  # => "bob-smith--p5w9-z27j"
```
# Features



# Coming in future (?)

- support for UUIDs for IDs (which will be encoded as an array of integers)

## Why this?

* Hashids are reversible, no need to persist the generated Id
* we don't override any methods or mess with ActiveRecord
* we support slugged IDs (eg 'my-amazing-product--p5w9-z27j')
* we support multiple model IDs encoded in one `EncodedId` (eg '7aq6-0zqw' decodes to `[78, 45]`)
* we use a reduced character set (Crockford alphabet),
  and ids split into groups of letters, ie we aim for 'human-readability'
* can be stable across environments, or not (you can set the salt to different values per environment)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id-rails

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install encoded_id-rails

Then run the generator to add the initializer:

    rails g encoded_id:rails:install

## Usage

TODO: Write usage instructions here

### Use on all models (but I recommend you don't)

Simply add the mixin to your `ApplicationRecord`:

```ruby 
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include EncodedId::WithEncodedId
  
  ...
end
```

However, I recommend you only use it on the models that need it.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/encoded_id-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
