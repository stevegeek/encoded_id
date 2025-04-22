# EncodedId and EncodedId::Rails

`encoded_id` lets you encode numerical or hex IDs into obfuscated strings that can be used in URLs. 

`encoded_id-rails` is a Rails integration that provides additional features for using `encoded_id` with ActiveRecord models.

```ruby
coder = ::EncodedId::ReversibleId.new(salt: my_salt)
coder.encode(123)
# => "p5w9-z27j"
coder.encode_hex("10f8c")
# => "w72a-y0az"
```

The obfuscated strings are reversible (they decode them back into the original IDs). 

Also supports encoding multiple IDs at once.

```ruby
my_salt = "salt!"
coder = ::EncodedId::ReversibleId.new(salt: my_salt)

# One of more values can be encoded
coder.encode([78, 45])
# => "z2j7-0dmw"

# The encoded string can then be reversed back into the original IDs
coder.decode("z2j7-0dmw")
# => [78, 45]

# The decoder can be resilient to easily confused characters
coder.decode("z2j7-Odmw") # (note the capital 'o' instead of zero)
# => [78, 45]
```

### Rails Integration

The `encoded_id-rails` gem (`EncodedId::Rails`) brings EncodedId to Rails and `ActiveRecord` models.

It lets you turn numeric or hex **IDs into reversible and human friendly obfuscated strings**.

You can use it in routes for example, to go from something like `/users/725` to `/users/bob-smith--usr_p5w9-z27j` with minimal effort.

### Rails Integration Features

- 🔄 encoded IDs are reversible (as documented above)
- 💅 supports slugged IDs (eg `my-cool-product-name--p5w9-z27j`) that are URL friendly (assuming your alphabet is too)
- 🔖 supports annotated IDs to help identify the model the encoded ID belongs to (eg for a `User` the encoded ID might be `user_p5w9-z27j`)
- 👓 encoded string can be split into groups of letters to improve human-readability (eg `abcd-efgh`)
- 👥 supports multiple IDs encoded in one encoded string (eg imagine the encoded ID `7aq60zqw` might decode to two IDs `[78, 45]`)

The Rails integration provides:

- methods to mixin to ActiveRecord models which will allow you to encode and decode IDs, and find
  or query by encoded IDs
- sensible defaults to allow you to get started out of the box

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model

  # An optional slug for the encoded ID string. This is prepended to the encoded ID string, and is solely 
  # to make the ID human friendly, or useful in URLs. It is not required for finding records by encoded ID.
  def name_for_encoded_id_slug
    full_name
  end
  
  # An optional prefix on the encoded ID string to help identify the model it belongs to.
  # Default is to use model's parameterized name, but can be overridden, or disabled.
  # Note it is not required for finding records by encoded ID.
  def annotation_for_encoded_id
    "usr"
  end
end

# You can find by the encoded ID
user = User.find_by_encoded_id("p5w9-z27j") # => #<User id: 78>
user.encoded_id                             # => "usr_p5w9-z27j"
user.slugged_encoded_id                     # => "bob-smith--usr_p5w9-z27j"

# You can find by a slugged & annotated encoded ID
user == User.find_by_encoded_id("bob-smith--usr_p5w9-z27j") # => true

# Encoded IDs can encode multiple IDs at the same time
users = User.find_all_by_encoded_id("7aq60zqw") # => [#<User id: 78>, #<User id: 45>]
```

See the [Rails Integration](#rails-integration) section for more details.

## Features

* 🔄 encoded IDs are reversible (uses Hashids, the old site is here https://github.com/hashids/hashids.github.io))
* 👥 supports multiple IDs encoded in one encoded string (eg `7aq6-0zqw` decodes to `[78, 45]`)
* 🔡 supports custom alphabets for the encoded string (at least 16 characters needed)
  - by default uses a variation of the Crockford reduced character set (https://www.crockford.com/base32.html)
  - 👓 easily confused characters (eg `i` and `j`, `0` and `O`, `1` and `I` etc) are mapped to counterpart characters, to help
      avoid common readability mistakes when reading/sharing
  - 🤬 build in profanity limitation
* 🤓 encoded string can be split into groups of letters to improve human-readability
  - eg `nft9hr834htu` as `nft9-hr83-4htu`
* 🥽 supports limits on length to prevent resource exhaustion on encoding and decoding
* configured with sensible defaults

I aim for 100% test coverage and have fuzz tested quite extensively. But please report any issues!

### For Rails

* 💅 slugged IDs (eg `my-cool-product-name--p5w9-z27j`) that are URL friendly
* 🔖 annotated IDs to help identify the model the encoded ID belongs to (eg for a `User` the encoded ID might be `user_p5w9-z27j`)
* 👓 encoded string can be split into groups of letters to improve human-readability (eg `abcd-efgh`)

#### Experimental

* support for encoding of hex strings (eg UUIDs), including multiple IDs encoded in one string

### Performance and benchmarking

This gem uses a custom HashId implementation that is significantly faster and more memory-efficient than the original `hashids` gem. 

For detailed benchmarks and performance metrics, see the [Custom HashId Implementation](#custom-hashid-implementation) section at the end of this README.

### Note on security of encoded IDs (hashids)

**Encoded IDs are not secure**. It maybe possible to reverse them via brute-force. They are meant to be used in URLs as 
an obfuscation. The algorithm is not an encryption.

Please read more on https://hashids.org/

## Compare to alternate Gems

- https://github.com/excid3/prefixed_ids
- https://github.com/namick/obfuscate_id
- https://github.com/norman/friendly_id
- https://github.com/SPBTV/with_uid
- https://github.com/bullet-train-co/bullet_train-core/blob/main/bullet_train-obfuscates_id/app/models/concerns/obfuscates_id.rb

## Installation

* [`encoded_id` standalone gem](https://rubygems.org/gems/encoded_id)
* [`encoded_id-rails` gem](https://rubygems.org/gems/encoded_id-rails)

### Standalone Gem

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install encoded_id


### Rails Gem

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id-rails

Then optionally run the generator to add the initializer. See [Rails Integration](#rails-integration) section for more details.

## Core Gem: Basic Usage

### `EncodedId::ReversibleId.new`

To create an instance of the encoder/decoder use `.new` with the `salt` option:

```ruby
coder = EncodedId::ReversibleId.new(
  # The salt is required
  salt: ...,
  # And then the following options are optional
  length: 8, 
  split_at: 4, 
  split_with: "-",
  alphabet: EncodedId::Alphabet.modified_crockford,
  hex_digit_encoding_group_size: 4 # Experimental
)
```

Note the `salt` value is required and should be a string of some length (greater than 3 characters). This is used to generate the encoded string. 

It will need to be the same value when decoding the string back into the original ID. If the salt is changed, the encoded
strings will be different and possibly decode to different IDs.

### Options

The encoded ID is configurable. The following can be changed:

- the length, eg 8 characters for `p5w9-z27j`
- the alphabet used in it (min 16 characters)
- and the number of characters to split the output into and the separator

### `length`

`length`: the minimum length of the encoded string. The default is 8 characters.

The actual length of the encoded string can be longer if the inputs cannot be represented in the minimum length.

### `max_length`

`max_length`: the maximum length of the encoded string. The default is 128 characters.

The maximum length represents both the longest encoded string that will be generated and also a limit on
the maximum input length that will be decoded. If the encoded string exceeds `max_length` then a
`EncodedIdLengthError` will be raised. If the input exceeds `max_length` then a `InvalidInputError` will
be raised. If `max_length` is set to `nil`, then no validation, even using the default will be performed.

### `max_inputs_per_id`

`max_inputs_per_id`: the maximum amount of IDs to be encoded together. The default is 32.

This maximum amount is used to limit:
- the length of array input passed to `encode`
- the length of integer array encoded in hex string(s) passed to `encode_hex` function.
`InvalidInputError` wil be raised when array longer than `max_inputs_per_id` is provided.

### `alphabet`

`alphabet`: the alphabet used in the encoded string. By default, it uses a variation of the Crockford reduced character set (https://www.crockford.com/base32.html).

`alphabet` must be an instance of `EncodedId::Alphabet`.

The default alphabet is `EncodedId::Alphabet.modified_crockford`.

To create a new alphabet, use `EncodedId::Alphabet.new`:

```ruby
alphabet = EncodedId::Alphabet.new("0123456789abcdef")
```

`EncodedId::Alphabet.new(characters, equivalences)`

**characters**

`characters`: the characters of the alphabet. Can be a string or array of strings.

Note that the `characters` of the alphabet must be at least 16 _unique_ characters long and must not contain any
whitespace characters.


```ruby
alphabet = EncodedId::Alphabet.new("ςερτυθιοπλκξηγφδσαζχψωβνμ")
coder = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: alphabet)
coder.encode(123)
# => "πφλχ-ψησω"
```

Note that larger alphabets can result in shorter encoded strings (but remember that `length` specifies the minimum length
of the encoded string).

**equivalences**

You can optionally pass an appropriate character `equivalences` mapping. This is used to map easily confused characters 
to their counterpart. 

`equivalences`: a hash of characters keys, with their equivalent alphabet character mapped to in the values. 

Note that the characters to be mapped:
- must not be in the alphabet, 
- must map to a character that is in the alphabet.

`nil` is the default value which means no equivalences are used.

```ruby
alphabet = EncodedId::Alphabet.new("!@#$%^&*()+-={}", {"_" => "-"})
coder = ::EncodedId::ReversibleId.new(salt: my_salt, alphabet: alphabet)
coder.encode(123)
# => "}*^(-^}*="
```

### `split_at` and `split_with`

For readability, the encoded string can be split into groups of characters. 

`split_at`: specifies the number of characters to split the encoded string into. Defaults to 4. 

`split_with`: specifies the separator to use between the groups. Default is `-`.

Set either to `nil` to disable splitting.

### `hex_digit_encoding_group_size`

**Experimental**

`hex_digit_encoding_group_size`: specifies the number of hex digits to encode in a group. Defaults to 4. Can be
between 1 and 32.

Can be used to control the size of the encoded string when encoding hex strings. Larger values will result in shorter
encoded strings for long inputs, and shorter values will result in shorter encoded strings for smaller inputs.

But note that bigger values will also result in larger markers that separate the groups so could end up increasing
the encoded string length undesirably.

See below section `Using with hex strings` for more details.

## `EncodedId::ReversibleId#encode`

`#encode(id)`: where `id` is an integer or array of integers to encode.

```ruby
coder.encode(123)
# => "p5w9-z27j"

# One of more values can be encoded
coder.encode([78, 45])
# => "z2j7-0dmw"
```

## `EncodedId::ReversibleId#decode`

`#decode(encoded_id)`: where `encoded_id` is a string to decode.

```ruby
# The encoded string can then be reversed back into the original IDs
coder.decode("z2j7-0dmw")
# => [78, 45]
```

## Using with hex strings

**Experimental** (subject to incompatible changes in future versions)

```ruby
# Hex input strings are also supported
coder.encode_hex("10f8c")
# => "w72a-y0az"
```

When encoding hex strings, the input is split into groups of hex digits, and each group is encoded separately as its
integer equivalent. In other words the input is converted into an array of integers and encoded as normal with the
`encode` method.

eg with `hex_digit_encoding_group_size=1` and inpu `f1`, is split into `f` and `1`, and then encoded as `15` and `1` 
respectively, ie `encode` is called with `[15, 1]`.

To encode multiple hex inputs the encoded string contains markers to indicate the start of a new hex input. This
marker is equal to an integer value which is 1 larger than the maximum value the hex digit encoding group size can
represent (ie it is `2^(hex_digit_encoding_group_size * 4)`).

So for a hex digit encoding group size of 4 (ie group max value is `0xFFFF`), the marker is `65536`

For example with `hex_digit_encoding_group_size=1` for the inputs `f1` and `e2` encoded together, the 
actual encoded integer array is `[15, 1, 16, 14, 2]`.

### `EncodedId::ReversibleId#encode_hex`

`encode_hex(hex_string)` , where `hex_string` is a string of hex digits or an array of hex strings.

```ruby
# UUIDs will result in long output strings...
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"
# 
# but there is an option to help reduce this... 
coder = ::EncodedId::ReversibleId.new(salt: my_salt, hex_digit_encoding_group_size: 32)
coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"
```

### `EncodedId::ReversibleId#decode_hex`

`decode_hex(encoded_id)` , where the output is an array of hex strings.

```ruby
coder.decode_hex("5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr")
# => ["9a566b8b-8618-42ab-8db7-a5a0276401fd"]
```

## Rails Integration

To use the Rails integration, you need to include the appropriate module in your model:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end
```

Then run the generator to add the initializer:

```bash
rails g encoded_id:rails:install
```

If you plan to use the `EncodedId::Rails::Persists` module to persist encoded IDs, you can generate the necessary migration:

```bash
rails g encoded_id:rails:add_columns User Product  # Add to multiple models
```

This will create a migration that adds the required columns and indexes to the specified models.

### Rails Configuration

The install generator will create an initializer file `config/initializers/encoded_id.rb`. It is documented
and should be self-explanatory.

You can configure:

- a global salt needed to generate the encoded IDs (if you dont use a global salt, you can set a salt per model)
- the size of the character groups in the encoded string (default is 4) 
- the separator between the character groups (default is '-')
- the alphabet used to generate the encoded string (default is a variation of the Crockford reduced character set)
- the minimum length of the encoded ID string (default is 8 characters)
- whether models automatically override `to_param` to return the encoded ID (default is false)

### Optional Rails Mixins

You can optionally include one of the following mixins to add default overrides to `#to_param`.

- `EncodedId::Rails::PathParam` - Makes `to_param` return the encoded ID
- `EncodedId::Rails::SluggedPathParam` - Makes `to_param` return the slugged encoded ID

This is so that an instance of the model can be used in path helpers and 
return the encoded ID string instead of the record ID by default.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam

  def name_for_encoded_id_slug
    full_name
  end
end

user = User.create(full_name: "Bob Smith")
Rails.application.routes.url_helpers.user_path(user) # => "/users/bob-smith--p5w9-z27j"
```

Alternatively, you can configure the gem to automatically override `to_param` for all models that include `EncodedId::Rails::Model` by setting the `model_to_param_returns_encoded_id` configuration option to `true`:

```ruby
# In config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  # ... other configuration options
  config.model_to_param_returns_encoded_id = true
end

# Then in your model
class User < ApplicationRecord
  include EncodedId::Rails::Model  # to_param will automatically return encoded_id
end

user = User.create(name: "Bob Smith")
Rails.application.routes.url_helpers.user_path(user) # => "/users/user_p5w9-z27j"
```

With this configuration, all models will behave as if they included `EncodedId::Rails::PathParam`.

### Persisting encoded IDs

You can optionally include the `EncodedId::Rails::Persists` mixin to persist the encoded ID in the database. This allows you to query directly by encoded ID in the database and enables more efficient lookups.

To use this feature, you can either:

1. Use the generator to create a migration for your models:

```bash
rails g encoded_id:rails:add_columns User Product
```

2. Or manually add the following columns to your model's table:

```ruby
add_column :users, :normalized_encoded_id, :string
add_column :users, :prefixed_encoded_id, :string
add_index :users, :normalized_encoded_id, unique: true
add_index :users, :prefixed_encoded_id, unique: true
```

Then include the mixin in your model:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end
```

The mixin will:

1. Store the encoded ID hash (without character grouping) in the `normalized_encoded_id` column
2. Store the complete encoded ID (with prefix if any) in the `prefixed_encoded_id` column
3. Add validations to ensure these columns are unique
4. Make these columns readonly after creation
5. Automatically update the persisted encoded IDs when the record is created
6. Ensure encoded IDs are reset when a record is duplicated
7. Provide safeguards to prevent inconsistencies

This enables direct database queries by encoded ID without having to decode them first. It also allows you to create database indexes on these columns for more efficient lookups.

#### Example Usage of Persisted Encoded IDs

Once you've set up the necessary database columns and included the `Persists` module, you can use the persisted encoded IDs:

```ruby
# Creating a record automatically sets the encoded IDs
user = User.create(name: "Bob Smith")
user.normalized_encoded_id  # => "p5w9z27j" (encoded ID without character grouping)
user.prefixed_encoded_id    # => "user_p5w9-z27j" (complete encoded ID with prefix)

# You can use these in ActiveRecord queries now of course, eg
User.where(normalized_encoded_id: ["p5w9z27j", "7aq60zqw"])

# If you need to refresh the encoded ID (e.g., you changed the salt)
user.set_normalized_encoded_id!

# The module protects against direct changes to these attributes
user.normalized_encoded_id = "something-else"
user.save  # This will raise ActiveRecord::ReadonlyAttributeError
```

### Example Rails usage with routes and controllers

```ruby
# Route
resources :users, param: :encoded_id, only: [:show]
```

```ruby
# Model
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam
end
```

```ruby
# Controller
class UsersController < ApplicationController
  def show
    @user = User.find_by_encoded_id!(params[:encoded_id])
  end
end
```

```erb 
<%= link_to "User", user_path %>
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. 

Run `bin/console` for an interactive prompt that will allow you to experiment.

### Running tests

Run `bundle exec rake test` to run the tests.

### Type check

First install RBS dependencies:

```bash
rbs collection install
```

Then run:

```bash
steep check
```

## See also

- https://hashids.org
- https://www.crockford.com/base32.html

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/encoded_id.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Custom HashId Implementation

Internally, `encoded_id` uses its own HashId implementation (`EncodedId::HashId`) instead of the original `hashids` gem. This custom implementation was created to improve both performance and memory usage. 

Recent benchmarks show significant improvements:

### Performance Comparison

```
| Test                      | Hashids (i/s) | EncodedId::HashId (i/s) | Speedup |
| ------------------------- | ------------ | --------------------- | ------- |
| #encode - 1 ID            |  131,000.979 |           197,586.231 |   1.51x |
| #decode - 1 ID            |   65,791.334 |            92,425.571 |   1.40x |
| #encode - 10 IDs          |   13,773.355 |            20,669.715 |   1.50x |
| #decode - 10 IDs          |    6,911.872 |             9,990.078 |   1.45x |
| #encode w YJIT - 1 ID     |  265,764.969 |           877,551.362 |   3.30x |
| #decode w YJIT - 1 ID     |  130,154.837 |           348,000.817 |   2.67x |
| #encode w YJIT - 10 IDs   |   27,966.457 |           100,461.237 |   3.59x |
| #decode w YJIT - 10 IDs   |   14,187.346 |            43,974.011 |   3.10x |
| #encode w YJIT - 1000 IDs |      268.140 |             1,077.855 |   4.02x |
| #decode w YJIT - 1000 IDs |      136.217 |               464.579 |   3.41x |
```

With YJIT enabled, the performance improvements are even more significant, with up to 4x faster operation for large inputs.

### Memory Usage Comparison

```
| Test                | Implementation   | Allocated Memory | Allocated Objects | Memory Reduction |
| ------------------- | ---------------- | ---------------- | ----------------- | ---------------- |
| encode small input  | Hashids          |          7.28 KB |               120 |                - |
|                     | EncodedId::HashId |            920 B |                 6 |           87.66% |
| encode large input  | Hashids          |        403.36 KB |              5998 |                - |
|                     | EncodedId::HashId |          8.36 KB |               104 |           97.93% |
| decode large input  | Hashids          |        366.88 KB |              5761 |                - |
|                     | EncodedId::HashId |         14.63 KB |               264 |           96.01% |
```

The memory usage improvements are dramatic, with up to 98% reduction in memory allocation for large inputs.

Run `bin/are_we_fast_yet` and `bin/memory_profile` in your environment to see the current performance difference.

## keywords
hash ID, friendly ID, obfuscate ID, rails, ActiveRecord, model, slug, vanity URL, friendly URL