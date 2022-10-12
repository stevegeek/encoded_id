# EncodedId

Encode your numerical IDs (eg record primary keys) into obfuscated strings that can be used in URLs. 

`::EncodedId::ReversibleId.new(salt: my_salt).encode(123)` => `"p5w9-z27j"`

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

Also supports UUIDs if needed

```
::EncodedId::ReversibleId.new(salt: my_salt).encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
=> "rppv-tg8a-cx8q-gu9e-zq15-jxes-4gpr-06xk-wfk8-aw"
```

## Features

Build with https://hashids.org

* Hashids are reversible, no need to persist the generated Id
* supports slugged IDs (eg 'beef-tenderloins-prime--p5w9-z27j')
* supports multiple IDs encoded in one `EncodedId` (eg '7aq6-0zqw' decodes to `[78, 45]`)
* supports encoding of hex strings (eg UUIDs), including mutliple IDs encoded in one `EncodedId`
* uses a reduced character set (Crockford alphabet) & ids split into groups of letters, ie 'human-readability'
* profanity limitation

To use with **Rails** check out the `encoded_id-rails` gem.

## Note on security of encoded IDs (hashids)

**Encoded IDs are not secure**. It maybe possible to reverse them via brute-force. They are meant to be used in URLs as 
an obfuscation. The algorithm is not an encryption.

Please read more on https://hashids.org/


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

TODO: Write usage instructions here

### Rails

To use with rails try the `encoded_id-rails` gem.

```ruby
    class User < ApplicationRecord
      include EncodedId::WithEncodedId
    end

    User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also 
run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version 
number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git 
commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/encoded_id.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## keywords
hash ID, friendly ID, obfuscate ID, rails, ActiveRecord, model, slug, vanity URL, friendly URL
