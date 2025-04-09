# EncodedId

Encode numerical or hex IDs into obfuscated strings that can be used in URLs. 

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

### Experimental

* support for encoding of hex strings (eg UUIDs), including multiple IDs encoded in one string

### Performance and benchmarking

This gem uses a custom HashId implementation that is significantly faster and more memory-efficient than the original `hashids` gem. 

For detailed benchmarks and performance metrics, see the [Custom HashId Implementation](#custom-hashid-implementation) section at the end of this README.


### Rails support `encoded_id-rails`

To use with **Rails** check out the [`encoded_id-rails`](https://github.com/stevegeek/encoded_id-rails) gem.

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
end

User.find_by_encoded_id("p5w9-z27j")
# => #<User id: 78>
```

### Note on security of encoded IDs (hashids)

**Encoded IDs are not secure**. It maybe possible to reverse them via brute-force. They are meant to be used in URLs as 
an obfuscation. The algorithm is not an encryption.

Please read more on https://hashids.org/

## Compare to alternate Gems

- https://github.com/excid3/prefixed_ids
- https://github.com/namick/obfuscate_id
- https://github.com/norman/friendly_id
- https://github.com/SPBTV/with_uid

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install encoded_id

## `EncodedId::ReversibleId.new`

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
