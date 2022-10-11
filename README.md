# EncodedId

Encode your numerical IDs (eg record primary keys) into obfuscated strings that can be used in URLs. 

`::EncodedId::ReversibleId.new(salt: my_salt).encode(123)` => `"7aq6-0zqw"`

The obfuscated strings are reversible, so you can decode them back into the original numerical IDs. Also supports 
encoding multiple IDs at once.

```
    reversibles = ::EncodedId::ReversibleId.new(salt: my_salt)
    reversibles.encode([78, 45])  # "7aq6-0zqw"
    reversibles.decode("7aq6-0zqw")  # [78, 45]
```

Length of the ID, the alphabet used, and the number of characters per group can be configured.

The custom alphabet (at least 16 characters needed) and character group sizes is to make the IDs easier to read or share.
Easily confused characters (eg `i` and `j`, `0` and `O`, `1` and `I` etc) are mapped to counterpart characters, to help 
common mistakes when sharing (eg customer over phone to customer service agent).

## Features

Build with https://hashids.org

* Hashids are reversible, no need to persist the generated Id
* supports slugged IDs (eg 'beef-tenderloins-prime--p5w9-z27j')
* supports multiple IDs encoded in one `EncodedId` (eg '7aq6-0zqw' decodes to `[78, 45]`)
* uses a reduced character set (Crockford alphabet) & ids split into groups of letters, ie 'human-readability'

To use with rails I recommend using the `encoded_id-rails` gem.

## Compared to alternate Gems

- https://github.com/excid3/prefixed_ids
- https://github.com/namick/obfuscate_id
- https://github.com/norman/friendly_id
- https://github.com/SPBTV/with_uid

## See also

- https://hashids.org
- https://www.crockford.com/wrmg/base32.html


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install encoded_id

## Usage

To use with Rails models, add the following to the model:

    class User < ApplicationRecord
      include EncodedId::WithUid


    end



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/encoded_id.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## keywords
hash ID, friendly ID, obfuscate ID, rails, ActiveRecord, model, slug, vanity URL, friendly URL
