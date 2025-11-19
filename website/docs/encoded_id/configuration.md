---
layout: default
title: Configuration
parent: EncodedId
nav_order: 2
---

# Configuration Options
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}
 
`EncodedId::ReversibleId` offers several configuration options to customize your encoded IDs. This guide covers all available options and provides examples.

## Basic Options

### Salt

The `salt` is a required string parameter that affects how IDs are encoded. It must be at least 4 characters long.

```ruby
# Good
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Will raise EncodedId::InvalidConfigurationError
coder = EncodedId::ReversibleId.new(salt: "abc") # Too short
```

**Important**: Changing the salt will change all encoded IDs. Make sure to keep your salt consistent, or you won't be able to decode previously encoded IDs.

### Length

The `length` parameter specifies the minimum length of the encoded string (default: 8 characters).

```ruby
# Default length (8)
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# Custom length (12)
coder = EncodedId::ReversibleId.new(salt: "my-salt", length: 12)
coder.encode(123)
# => "00p5-w9z2-7j00"
```

Note that the actual length may be longer if needed to represent the input values.

### Maximum Length

The `max_length` parameter sets a limit on how long encoded strings can be (default: 128 characters).

```ruby
# With default max_length (128)
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# With custom max_length
coder = EncodedId::ReversibleId.new(salt: "my-salt", max_length: 64)

# Disable max_length check
coder = EncodedId::ReversibleId.new(salt: "my-salt", max_length: nil)
```

If an encoded string exceeds `max_length`, an `EncodedId::EncodedIdLengthError` will be raised.

### Maximum Inputs Per ID

The `max_inputs_per_id` parameter limits how many IDs can be encoded in a single string (default: 32).

```ruby
# Default (32 max inputs)
coder = EncodedId::ReversibleId.new(salt: "my-salt")

# Allow 100 inputs max
coder = EncodedId::ReversibleId.new(salt: "my-salt", max_inputs_per_id: 100)

# Will raise EncodedId::InvalidInputError
coder.encode((1..101).to_a) # Too many inputs
```

### Encoder (Algorithm) {#encoder-algorithm}

The `encoder` parameter specifies which encoding algorithm to use (default: `:hashids`).

```ruby
# Default (HashIds algorithm)
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# Use Sqids algorithm (requires 'sqids' gem)
coder = EncodedId::ReversibleId.new(salt: "my-salt", encoder: :sqids)
coder.encode(123)
# => "k6jR-8Myo"
```

EncodedId supports two encoding algorithms:

1. `:hashids` - The original HashIds algorithm (default)
2. `:sqids` - The newer Sqids algorithm (requires 'sqids' gem)

**Important**: HashIds and Sqids produce different encodings and are not compatible with each other. Once you choose an encoder, stick with it, or your existing encoded IDs will no longer decode correctly.

To use the Sqids encoder, add the 'sqids' gem to your Gemfile:

```ruby
gem 'sqids'
```

If you attempt to use the Sqids encoder without the gem installed, an `EncodedId::InvalidConfigurationError` will be raised.

Note: at the moment, Sqids are slower to encode than Hashids (especially if using the blocklist feature). However, they are faster to decode than Hashids.

To get the most out of Sqids encode performance consider a small (or no) blocklist (set the `blocklist:` option) as the gems default blocklist is large.

### Blocklist {#blocklist}

The `blocklist` parameter allows you to prevent certain words from appearing in encoded IDs (default: `nil`).

```ruby
# With blocklist
coder = EncodedId::ReversibleId.new(
  salt: "my-salt", 
  blocklist: ["bad", "word", "offensive"]
)

# Can provide as Array or Set
coder = EncodedId::ReversibleId.new(
  salt: "my-salt", 
  blocklist: Set.new(["bad", "word", "offensive"])
)
```

The behavior differs depending on the encoder:

* With HashIds: If a generated ID contains a blocklisted word, an `EncodedId::InvalidInputError` will be raised
* With Sqids: The algorithm automatically avoids generating IDs with blocklisted words

## Formatting Options {#formatting-options}

### Split At

The `split_at` parameter specifies after how many characters to split the encoded string (default: 4).

```ruby
# Default (split every 4 characters)
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# Split every 3 characters
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_at: 3)
coder.encode(123)
# => "p5w-9z2-7j"

# Disable splitting
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_at: nil)
coder.encode(123)
# => "p5w9z27j"
```

### Split With

The `split_with` parameter specifies the character to use when splitting the encoded string (default: "-").

```ruby
# Default (split with "-")
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# Split with "_"
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_with: "_")
coder.encode(123)
# => "p5w9_z27j"

# Disable splitting
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_with: nil)
coder.encode(123)
# => "p5w9z27j"
```

**Note**: The `split_with` character must not be part of the alphabet.

## Alphabet Customization {#alphabet-customization}

### Using a Custom Alphabet

The `alphabet` parameter lets you customize the characters used in encoded IDs.

```ruby
# Default alphabet (modified Crockford)
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.encode(123)
# => "p5w9-z27j"

# Hexadecimal alphabet
hex_alphabet = EncodedId::Alphabet.new("0123456789abcdef")
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: hex_alphabet)
coder.encode(123)
# => "d783-ca9d"

# Greek alphabet
greek_alphabet = EncodedId::Alphabet.new("αβγδεζηθικλμνξοπρστυφχψω")
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: greek_alphabet)
coder.encode(123)
# => "θεαψ-ζκυο"
```

### Character Equivalences

The alphabet can include character equivalences to handle easily confused characters:

```ruby
# Default alphabet already has equivalences for easily confused chars like 0/O, 1/I/l
coder = EncodedId::ReversibleId.new(salt: "my-salt")
coder.decode("p5w9-z27j") # => [123]
coder.decode("p5w9-z27J") # => [123] (capital J mapped to lowercase j)

# Custom alphabet with equivalences
alphabet = EncodedId::Alphabet.new(
  "0123456789ABCDEF", 
  {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"}
)
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: alphabet)
coder.encode(123)
# => "D783-CA9D"
coder.decode("d783-ca9d") # => [123] (lowercase letters mapped to uppercase)
```

## Hex Encoding Options (Experimental)

### Hex Digit Encoding Group Size

The `hex_digit_encoding_group_size` parameter controls how hex strings are encoded (default: 4). Must be between 1 and 32.

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt", hex_digit_encoding_group_size: 32)
```

Larger values produce shorter encoded strings for long inputs (e.g., UUIDs). See [Hex Encoding Features](advanced-topics.html#hex-encoding-features-experimental) for detailed examples and optimization guidance.