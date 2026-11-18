# Configuration

## The initializer

`bin/rails generate encoded_id:rails:install` asks for an encoder (or takes `--encoder=sqids` or
`--encoder=hashids`) and writes `config/initializers/encoded_id.rb` with every option commented out. Settings go in
a `configure` block:

```ruby
EncodedId::Rails.configure do |config|
  config.salt = ENV.fetch("ENCODED_ID_SALT")
  config.encoder = :sqids
  config.id_length = 8
end
```

`configure` yields a copy of the current configuration, validates it when the block returns, freezes it and makes
it current. Calling it again replaces the configuration; models build new coders for the new one.
`EncodedId::Rails.configuration` returns the current, frozen configuration, so reading works but assigning raises
`FrozenError`.

Validation raises `ArgumentError` if `group_separator` uses a character of the alphabet, or if
`slugged_id_separator` or `annotated_id_separator` is blank, equals the group separator, or uses a character of the
alphabet. The check runs against the final alphabet, whatever order the block sets things in. `encoder=` raises
`ArgumentError` for anything but `:sqids` or `:hashids`.

## Options

| Option | Default | Per model | Meaning |
|---|---|---|---|
| `salt` | `nil` | `salt:` | Base of each model's salt, 4+ characters. Required by models with either encoder |
| `encoder` | `:sqids` | yes | `:sqids` or `:hashids` |
| `id_length` | `8` | yes | Minimum hash length, before separators |
| `character_group_size` | `4` | yes | Characters per group; `nil` for no grouping |
| `group_separator` | `"-"` | as `separator:` | Group separator |
| `alphabet` | `EncodedId::Alphabet.modified_crockford` | yes | An `EncodedId::Alphabet` |
| `max_length` | `128` | yes | Longest hash encoded or decoded; `nil` for no limit |
| `max_inputs_per_id` | `32` | yes | Most IDs in one encoded ID |
| `hex_digit_encoding_group_size` | `4` | yes | Passed to the core coder |
| `blocklist` | `EncodedId::Blocklist.empty` | yes | `Blocklist`, Array or Set |
| `blocklist_mode` | `:length_threshold` | yes | `:length_threshold`, `:always` or `:raise_if_likely` |
| `blocklist_max_length` | `32` | yes | Length limit for `:length_threshold` |
| `downcase_on_decode` | `false` | yes | Lower-case input before decoding (lower-case alphabets only) |
| `annotation_method_name` | `:annotation_for_encoded_id` | no | Method giving the prefix; `nil` for no prefix |
| `annotated_id_separator` | `"_"` | no | Between prefix and hash |
| `slug_value_method_name` | `:name_for_encoded_id_slug` | no | Method giving the slug |
| `slugged_id_separator` | `"--"` | no | Between slug and the rest |
| `model_to_param_returns_encoded_id` | `false` | no | Include `PathParam` in every model that includes `Model` |

`model_to_param_returns_encoded_id` is read when a model includes `EncodedId::Rails::Model`, so set it in the
initializer, before models load.

## Per-model options

```ruby
class Order < ApplicationRecord
  include EncodedId::Rails::Model

  encoded_id_config encoder: :hashids, id_length: 12, separator: ".", blocklist: EncodedId::Blocklist.minimal
end
```

`encoded_id_config` accepts the options marked "per model" above. The group separator is `separator:` here, not
`group_separator:`. Other keys are ignored. Subclasses inherit the options of the nearest ancestor that set them;
a subclass that calls `encoded_id_config` replaces them rather than merging. The options and their values are
frozen.

`encode_encoded_id` and `decode_encoded_id` also take these options per call, for one-off formats:

```ruby
Order.encode_encoded_id(order.id, character_group_size: nil)   # => "dchf51kr"
Order.encode_encoded_id(order.id, id_length: 12)               # => "dchf-51kr-42yp"
```

A call with options builds a new coder each time; calls without options reuse the model's cached coder.

## Salts

The default `encoded_id_salt` is `"#{model_name}/#{config.salt}"`, so with Hashids each model, including each
STI subclass, encodes the same number differently. It raises `StandardError` if the class has no name or
`config.salt` is missing or shorter than 4 characters, whatever the encoder. Sqids ignores the salt.

Override it for a fixed salt, for example to share Hashids IDs across an STI hierarchy:

```ruby
class Vehicle < ApplicationRecord
  include EncodedId::Rails::Model

  def self.encoded_id_salt = "Vehicle/#{EncodedId::Rails.configuration.salt}"
end
```

`encoded_id_config salt: "..."` sets the salt as given, without the model name.

With Sqids, models with the same options share hashes, so an ID of one model decodes to the same number through
another. To keep them apart, give a model its own alphabet (for example a fixed shuffle of the default characters).

## Caching

A model builds one coder for the current configuration and its `encoded_id_options`, and reuses it until either
changes. `encoded_id_salt` and `encoded_id_options` are therefore called once per configuration: they must return
the same values every time, and the values are frozen. To inspect what a model uses:

```ruby
Order.encoded_id_coder.settings   # an EncodedId::Rails::Coder::Settings (encoder, salt, alphabet, ...)
Order.encoded_id_options          # the per-model options
Order.encoded_id_salt
```

`EncodedId::Rails::Coder.new` takes a `Coder::Settings`; build one with
`EncodedId::Rails::Coder::Settings.resolve(configuration:, salt:, options:)`.

## Thread safety

Model encode and decode methods (`encoded_id`, `encode_encoded_id`, `decode_encoded_id`, ...) and finders
(`find_by_encoded_id`, ...) are safe to call from many threads. `configure` changes process-wide settings: call it
at boot, in `config/initializers`, not while the app serves requests.

## Tests

```ruby
require "encoded_id/rails/test_helper"

class OrderTest < ActiveSupport::TestCase
  include EncodedId::Rails::TestHelper

  test "finds an order by a Hashids encoded ID" do
    with_encoded_id_configuration(encoder: :hashids, salt: "test-salt") do
      assert_equal order, Order.find_by_encoded_id(order.encoded_id)
    end
  end
end
```

`with_encoded_id_configuration(**overrides)` runs the block with those settings changed, then restores the previous
configuration even if the block raises, and returns the block's value. It replaces the configuration for the whole
process, so tests that use it must not run in parallel threads (process-based parallel tests are fine).

## Upgrading to 2.0

- Replace assignments such as `EncodedId::Rails.configuration.salt = ...` with `configure`, or with
  `with_encoded_id_configuration` in tests.
- Check that no separator uses an alphabet character, since `configure` now raises at boot.
- Make `encoded_id_salt` and `encoded_id_options` return fixed values.
- Code that builds `EncodedId::Rails::Coder` directly must pass `Coder::Settings.resolve(...)`.
