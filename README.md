# EncodedId and EncodedId::Rails

`encoded_id` lets you encode numerical or hex IDs into obfuscated strings that can be used in URLs. 

`encoded_id-rails` is a Rails integration that provides additional features for using `encoded_id` with ActiveRecord models.

👉 **Full documentation available at [encoded-id.onrender.com](https://encoded-id.onrender.com)**

## Quick Example

```ruby
coder = ::EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# The encoded strings are reversible
coder.decode("p5w9-z27j")
# => [123]

# Supports encoding multiple IDs at once
coder.encode([78, 45])
# => "z2j7-0dmw"

# Can also be used with ActiveRecord models
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  # Optional slug for the encoded ID
  def name_for_encoded_id_slug
    full_name
  end
end

# Find by encoded ID
user = User.find_by_encoded_id("p5w9-z27j") # => #<User id: 78>
user.encoded_id                             # => "user_p5w9-z27j"
user.slugged_encoded_id                     # => "bob-smith--user_p5w9-z27j"
```

## Key Features

* 🔄 **Reversible** - Encoded IDs can be decoded back to the original values
* 👥 **Multiple IDs** - Encode multiple numeric IDs in one string
* 🚀 **Choose your encoding** - Supports `Hashids` and `Sqids` out of the box, or use your own custom encoder
* 🔡 **Custom alphabets** - Use your preferred character set
* 👓 **Human-readable** - Character grouping for better readability
* 🔠 **Character mapping** - Maps easily confused characters for better usability
* 🤬 **Profanity blocking** - Built-in blocklist support

### Rails Integration Features

* 🏷️ **ActiveRecord integration** - Use with ActiveRecord models
* 🔑 **Per-model salt** - Use a custom salt for encoding per model
* 💅 **Slugged IDs** - URL-friendly slugs like `my-product--p5w9-z27j`
* 🔖 **Annotated IDs** - Model type indicators like `user_p5w9-z27j`
* 🔍 **Finder methods** - Find records using encoded IDs
* 🛣️ **URL params** - `to_param` with encoded IDs
* 💾 **Persistence** - Optional database persistence for efficient lookups


## Standalone Gem


```bash
# Add to Gemfile
bundle add encoded_id

# Or install directly
gem install encoded_id
```

See the [EncodedId API](https://encoded-id.onrender.com/docs/encoded_id/api) documentation for more details.

## Rails Integration Gem

```bash
# Add to Gemfile
bundle add encoded_id-rails

# Then run the generator
rails g encoded_id:rails:install
```

See the [Rails Integration](https://encoded-id.onrender.com/docs/encoded_id_rails) documentation for more details.

## Security Note

**Encoded IDs are not secure**. They are meant to provide obfuscation, not encryption. Do not use them as a security mechanism.

## Compare to Alternate Gems

- [prefixed_ids](https://github.com/excid3/prefixed_ids)
- [obfuscate_id](https://github.com/namick/obfuscate_id)
- [friendly_id](https://github.com/norman/friendly_id)
- [with_uid](https://github.com/SPBTV/with_uid)
- [bullet_train-obfuscates_id](https://github.com/bullet-train-co/bullet_train-core/blob/main/bullet_train-obfuscates_id/app/models/concerns/obfuscates_id.rb)

For a detailed comparison, see the [Compared to Other Gems](https://encoded-id.onrender.com/docs/compared-to) documentation page.

## Documentation

Visit [encoded-id.onrender.com](https://encoded-id.onrender.com) for comprehensive documentation including:

- [EncodedId Core API](https://encoded-id.onrender.com/docs/encoded_id/api)
- [Rails Integration API](https://encoded-id.onrender.com/docs/encoded_id_rails/api)
- [Configuration Options](https://encoded-id.onrender.com/docs/encoded_id/configuration)
- [Examples](https://encoded-id.onrender.com/docs/encoded_id/examples)
- [Advanced Topics](https://encoded-id.onrender.com/docs/advanced-topics)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Run `bundle exec rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/encoded_id.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).