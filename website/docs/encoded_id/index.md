---
layout: default
title: EncodedId
nav_order: 2
has_children: true
permalink: /docs/encoded_id/
---

# EncodedId
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

`encoded_id` is a Ruby gem that lets you encode numerical or hex IDs into obfuscated strings that can be used in URLs.

## Why use EncodedId?

- **Obfuscate database IDs**: Hide sequential numeric IDs from users
- **Reversible**: Unlike UUIDs, you can easily decode back to the original ID
- **URL-friendly**: Generate compact, user-friendly IDs for your URLs
- **Configurable**: Customize the alphabet, length, and formatting
- **Multiple algorithms**: Choose between HashIds and Sqids encoding engines
- **Blocklist support**: Prevent generating IDs containing sensitive or offensive words

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'encoded_id'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install encoded_id
```

## Quick Start

### Using Sqids (Default)

```ruby
# Create a Sqids encoder (default, no salt required)
coder = EncodedId::ReversibleId.sqids

# Encode a numeric ID
encoded = coder.encode(123)
# => (output varies based on configuration)

# Decode back to the original ID
coder.decode(encoded)
# => [123]

# Encode multiple IDs at once
multi_encoded = coder.encode([78, 45])
# => (output varies)

# Decode multiple IDs
coder.decode(multi_encoded)
# => [78, 45]
```

### Using Hashids

```ruby
# Create a Hashids encoder with your own secret salt (required)
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Encode a numeric ID
encoded = coder.encode(123)
# => "m3pm-8anj"

# Decode back to the original ID
coder.decode("m3pm-8anj")
# => [123]

# Encode multiple IDs at once
coder.encode([78, 45])
# => "ny9y-sd7p"

# Decode multiple IDs
coder.decode("ny9y-sd7p")
# => [78, 45]
```

### Blocklist Support

Prevent specific words from appearing in encoded IDs:

```ruby
# With Hashids
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", blocklist: ["bad", "word"])

# With Sqids (uses blocklist for alphabet shuffling)
coder = EncodedId::ReversibleId.sqids(blocklist: ["bad", "word"])
```

See [Blocklist Configuration](#blocklist) for details on encoder-specific behavior.

### Security Note

**Encoded IDs are not secure**. It may be possible to reverse them via brute-force. They are meant to be used in URLs as an obfuscation. The algorithm is not an encryption.

As of version 1.0.0, **Sqids is the default encoder**. Hashids is still supported but is officially deprecated by the Hashids project in favor of Sqids.

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/) (note: this specifically applies to the Hashids encoder)

For more details, please refer to:
- [Sqids](https://sqids.org/) (Default)
- [Hashids](https://hashids.org/) (Deprecated)

## Configuration Options

`EncodedId::ReversibleId` offers several configuration options to customize your encoded IDs. This section covers all available options and provides examples.

### Basic Options

#### Salt

The `salt` parameter is **required for Hashids encoder** and affects how IDs are encoded. It must be at least 4 characters long. Sqids does not use or require a salt.

```ruby
# Hashids requires salt
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Sqids does not use salt
coder = EncodedId::ReversibleId.sqids

# Will raise EncodedId::InvalidConfigurationError
coder = EncodedId::ReversibleId.hashid(salt: "abc") # Too short
```

**Important**: Changing the salt will change all encoded IDs. Make sure to keep your salt consistent, or you won't be able to decode previously encoded IDs.

#### Minimum Length

The `min_length` parameter specifies the minimum length of the encoded string (default: 8 characters).

```ruby
# Default min_length (8)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"

# Custom min_length (12)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", min_length: 12)
coder.encode(123)
# => "00m3-pm8a-nj00"

# With Sqids
coder = EncodedId::ReversibleId.sqids(min_length: 12)
coder.encode(123)
# => (varies based on alphabet shuffling)
```

Note that the actual length may be longer if needed to represent the input values.

#### Maximum Length

The `max_length` parameter sets a limit on how long encoded strings can be (default: 128 characters).

```ruby
# With default max_length (128)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# With custom max_length
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", max_length: 64)

# Disable max_length check
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", max_length: nil)

# With Sqids
coder = EncodedId::ReversibleId.sqids(max_length: 64)
```

If an encoded string exceeds `max_length`, an `EncodedId::EncodedIdLengthError` will be raised.

#### Maximum Inputs Per ID

The `max_inputs_per_id` parameter limits how many IDs can be encoded in a single string (default: 32).

```ruby
# Default (32 max inputs)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Allow 100 inputs max
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", max_inputs_per_id: 100)

# With Sqids
coder = EncodedId::ReversibleId.sqids(max_inputs_per_id: 100)

# Will raise EncodedId::InvalidInputError
coder.encode((1..101).to_a) # Too many inputs
```

#### Encoder (Algorithm) {#encoder-algorithm}

EncodedId supports two encoding algorithms. Use factory methods to create the appropriate encoder:

```ruby
# Sqids algorithm (default, no salt required)
coder = EncodedId::ReversibleId.sqids
coder.encode(123)
# => (varies based on alphabet shuffling)

# Or explicitly call with no arguments (defaults to Sqids)
coder = EncodedId::ReversibleId.new
coder.encode(123)
# => (same as .sqids)

# Hashids algorithm (requires salt)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"
```

EncodedId supports two encoding algorithms:

1. **Sqids** - The Sqids algorithm (default as of v1.0.0, automatically included). Use `.sqids` factory method.
2. **Hashids** - The HashIds algorithm (deprecated by Hashids project, supported for backwards compatibility). Use `.hashid` factory method.

**Important**: HashIds and Sqids produce different encodings and are not compatible with each other. Once you choose an encoder, stick with it, or your existing encoded IDs will no longer decode correctly.

**Note**: As of v1.0.0, Sqids is a runtime dependency and is automatically included - no need to add it separately to your Gemfile.

**Performance**: Sqids are currently slower to encode than HashIds (especially when using the blocklist feature), but they are faster to decode than HashIds.

To get the most out of Sqids encode performance, use a small blocklist or disable it entirely by passing `blocklist: EncodedId::Blocklist.empty`.

#### Blocklist {#blocklist}

The `blocklist` parameter allows you to prevent certain words from appearing in encoded IDs. The default is `Blocklist.empty`.

```ruby
# With Hashids - provide custom blocklist
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: ["bad", "word", "offensive"]
)

# With Sqids - provide custom blocklist
coder = EncodedId::ReversibleId.sqids(
  blocklist: ["bad", "word", "offensive"]
)

# Can provide as Array or Set
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: Set.new(["bad", "word", "offensive"])
)
```

##### Built-in Blocklists

EncodedId provides three built-in blocklists:

```ruby
# Empty blocklist (no filtering)
coder = EncodedId::ReversibleId.sqids(blocklist: EncodedId::Blocklist.empty)

# Minimal blocklist (51 common offensive words)
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: EncodedId::Blocklist.minimal
)

# Sqids default blocklist (560 words from Sqids project)
coder = EncodedId::ReversibleId.sqids(
  blocklist: EncodedId::Blocklist.sqids_blocklist
)
```

The behavior differs depending on the encoder:

* **With Hashids**: If a generated ID contains a blocklisted word, an `EncodedId::BlocklistError` will be raised
* **With Sqids**: The algorithm automatically avoids generating IDs with blocklisted words by shuffling the alphabet

##### Blocklist Modes

The `blocklist_mode` parameter controls when blocklist checking occurs (default: `:length_threshold`):

```ruby
# :length_threshold (default) - Only check short IDs
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :length_threshold,
  blocklist_max_length: 32  # Only check IDs ≤ 32 characters
)

# :always - Check all IDs regardless of length
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :always
)

# :raise_if_likely - Raise error if config likely causes issues
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :raise_if_likely,
  min_length: 8  # Will raise if min_length > blocklist_max_length
)
```

**Blocklist Mode Reference:**

| Mode | Behavior | Performance | Use Case |
|------|----------|-------------|----------|
| `:length_threshold` | Only checks IDs ≤ `blocklist_max_length` | Best for most cases | Default, balances safety and performance |
| `:always` | Checks all IDs regardless of length | Slower for long IDs | Maximum filtering, when performance isn't critical |
| `:raise_if_likely` | Raises error if config suggests issues | N/A (validation only) | Catch misconfigurations early in development |

**Performance Note**: Longer IDs are statistically less likely to contain blocklisted words. The `:length_threshold` mode (default) provides a good balance by only checking short IDs where collisions are more probable.

##### Blocklist Max Length

The `blocklist_max_length` parameter sets the threshold for `:length_threshold` mode (default: 32):

```ruby
# Custom threshold - only check IDs ≤ 50 characters
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: EncodedId::Blocklist.minimal,
  blocklist_mode: :length_threshold,
  blocklist_max_length: 50
)
```

### Formatting Options {#formatting-options}

#### Split At

The `split_at` parameter specifies after how many characters to split the encoded string (default: 4).

```ruby
# Default (split every 4 characters)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"

# Split every 3 characters
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_at: 3)
coder.encode(123)
# => "m3p-m8a-nj"

# Disable splitting
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_at: nil)
coder.encode(123)
# => "m3pm8anj"

# Works with Sqids too
coder = EncodedId::ReversibleId.sqids(split_at: 3)
```

#### Split With

The `split_with` parameter specifies the character to use when splitting the encoded string (default: "-").

```ruby
# Default (split with "-")
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"

# Split with "_"
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_with: "_")
coder.encode(123)
# => "m3pm_8anj"

# Disable splitting
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_with: nil)
coder.encode(123)
# => "m3pm8anj"

# Works with Sqids too
coder = EncodedId::ReversibleId.sqids(split_with: "_")
```

**Note**: The `split_with` character must not be part of the alphabet.

### Alphabet Customization {#alphabet-customization}

#### Using a Custom Alphabet

The `alphabet` parameter lets you customize the characters used in encoded IDs.

```ruby
# Default alphabet (modified Crockford base32)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"

# Hexadecimal alphabet
hex_alphabet = EncodedId::Alphabet.new("0123456789abcdef")
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: hex_alphabet)
coder.encode(123)
# => "923b-a293"

# Greek alphabet
greek_alphabet = EncodedId::Alphabet.new("αβγδεζηθικλμνξοπρστυφχψω")
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: greek_alphabet)
coder.encode(123)
# => (output in Greek characters)

# Works with Sqids too
coder = EncodedId::ReversibleId.sqids(alphabet: hex_alphabet)
```

#### Character Equivalences

The alphabet can include character equivalences to handle easily confused characters:

```ruby
# Default alphabet already has equivalences for easily confused chars like o/0, i/j, l/1
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.decode("m3pm-8anj") # => [123]
coder.decode("m3pm-8ani") # => [123] (i mapped to j)

# Custom alphabet with equivalences
alphabet = EncodedId::Alphabet.new(
  "0123456789ABCDEF",
  {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"}
)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: alphabet)
coder.encode(123)
# => "923B-A293"
coder.decode("923b-a293") # => [123] (lowercase letters mapped to uppercase)
```

### Hex Encoding Options (Experimental)

#### Hex Digit Encoding Group Size

The `hex_digit_encoding_group_size` parameter controls how hex strings are encoded (default: 4). Must be between 1 and 32.

```ruby
# With Hashids
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", hex_digit_encoding_group_size: 32)

# With Sqids
coder = EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 32)
```

Larger values produce shorter encoded strings for long inputs (e.g., UUIDs). See [Hex Encoding Features](#hex-encoding-features-experimental) for detailed examples and optimization guidance.

## Examples

This section provides various examples of using EncodedId in different scenarios.

### Basic Usage

#### Encoding and Decoding Simple IDs

```ruby
# Using Hashids encoder
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Encode a single ID
encoded = coder.encode(123)
# => "m3pm-8anj"

# Decode back to the original ID
decoded = coder.decode(encoded)
# => [123]

# The first element is our original ID
decoded.first
# => 123
```

#### Encoding and Decoding Multiple IDs

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Encode multiple IDs
encoded = coder.encode([78, 45, 92])
# => "qfxs-b2xe-b"

# Decode back to the original IDs
decoded = coder.decode(encoded)
# => [78, 45, 92]
```

#### Character Case Resilience

EncodedId can handle uppercase input when the `downcase` parameter is enabled:

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Encode an ID
encoded = coder.encode(123)
# => "m3pm-8anj"

# Decode with uppercase letters using downcase parameter
coder.decode("M3PM-8ANJ", downcase: true)
# => [123]

# Default behavior (downcase: false) requires exact case match
coder.decode("m3pm-8anj", downcase: false)
# => [123]

# Without downcase: true, uppercase will not decode correctly
coder.decode("M3PM-8ANJ", downcase: false)
# => []
```

### Using Different Encoders

#### Sqids Encoder (Default)

```ruby
# The default encoder is Sqids (no salt required)
coder = EncodedId::ReversibleId.sqids

# Encode using Sqids
encoded = coder.encode(123)
# => (output varies based on alphabet shuffling)

# Explicitly calling .new with no arguments also defaults to Sqids
coder = EncodedId::ReversibleId.new
encoded = coder.encode(123)
```

#### Hashids Encoder

To use the Hashids encoder:

```ruby
# Hashids requires a salt
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"
```

### Blocklist Support

Prevent specific words from appearing in encoded IDs. Behavior differs by encoder - HashIds raises errors while Sqids automatically avoids blocklisted words.

```ruby
# Hashids: raises error if blocklisted word appears
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  blocklist: ["bad", "word"]
)

begin
  coder.encode(12345)
rescue EncodedId::BlocklistError => e
  puts e.message  # => Generated ID contains blocklisted word
end

# Sqids: automatically avoids blocklisted words by shuffling alphabet
coder = EncodedId::ReversibleId.sqids(
  blocklist: ["bad", "word"]
)
coder.encode(12345)  # => Safe ID without blocklisted words
```

### Formatting Options

Customize how encoded IDs are formatted:

```ruby
# Custom separator and group size
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_at: 3, split_with: ".")
coder.encode(123)  # => "m3p.m8a.nj"

# Disable grouping
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", split_at: nil)
coder.encode(123)  # => "m3pm8anj"

# Works with Sqids too
coder = EncodedId::ReversibleId.sqids(split_at: 3, split_with: ".")
```

### Custom Alphabets

Use custom character sets for encoding:

```ruby
# Hexadecimal alphabet with Hashids
hex_alphabet = EncodedId::Alphabet.new("0123456789abcdef")
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: hex_alphabet)
coder.encode(123)  # => "923b-a293"

# With character equivalences (e.g., lowercase maps to uppercase)
alphabet = EncodedId::Alphabet.new("0123456789ABCDEF", {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"})
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", alphabet: alphabet)
coder.encode(123)  # => "923B-A293"
coder.decode("923b-a293")  # => [123]

# Works with Sqids too
coder = EncodedId::ReversibleId.sqids(alphabet: hex_alphabet)
```

### Advanced Options

#### Setting Minimum Length

```ruby
# Set minimum length to 12 characters with Hashids
coder = EncodedId::ReversibleId.hashid(
  salt: "my-secret-salt",
  min_length: 12
)

encoded = coder.encode(123)
# => "00m3-pm8a-nj00"

# With Sqids
coder = EncodedId::ReversibleId.sqids(min_length: 12)
```

#### Setting Maximum Length

```ruby
# Set maximum length to 16 characters
coder = EncodedId::ReversibleId.hashid(
  salt: "my-secret-salt",
  max_length: 16
)

# This will work fine
encoded = coder.encode(123)
# => "m3pm-8anj"

# But this might raise an error if the encoded ID exceeds the max length
begin
  huge_number = 10**100
  encoded = coder.encode(huge_number)
rescue EncodedId::EncodedIdLengthError => e
  puts "Error: #{e.message}"
  # => Error: Encoded ID exceeds maximum allowed length of 16 characters
end
```

#### Limiting Maximum Inputs

```ruby
# Set maximum number of inputs to 5
coder = EncodedId::ReversibleId.hashid(
  salt: "my-secret-salt",
  max_inputs_per_id: 5
)

# This works fine
encoded = coder.encode([1, 2, 3, 4, 5])
# => (encoded output)

# But this raises an error
begin
  encoded = coder.encode([1, 2, 3, 4, 5, 6])
rescue EncodedId::InvalidInputError => e
  puts "Error: #{e.message}"
  # => Error: 6 integer IDs provided, maximum amount of IDs is 5
end
```

### Experimental: Hex Encoding

Encode hexadecimal strings including UUIDs:

```ruby
# With Hashids
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
encoded = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => (encoded value)

# Decoded hex values have hyphens removed
coder.decode_hex(encoded)
# => ["9a566b8b861842ab8db7a5a0276401fd"]

# With Sqids
coder = EncodedId::ReversibleId.sqids
encoded = coder.encode_hex("f1")
decoded = coder.decode_hex(encoded)
# => ["f1"]
```

See [Hex Encoding Features](#hex-encoding-features-experimental) for UUID optimization and detailed examples.

## Advanced Topics

### Performance Considerations

In general, at the moment, Sqids are slower to encode than Hashids (especially if using the blocklist feature). However, they are faster to decode than Hashids. With YJIT enabled, the differences in speeds are smaller.

To get the most out of Sqids encode performance, consider a small (or no) blocklist (set the `blocklist:` option). The default Sqids blocklist is very costly on encode time, but extensive.

### Security Considerations

It's important to understand the security implications of using encoded IDs.

#### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/)

### Salts

**Changing the salt**: If you change your salt, all previously encoded IDs will no longer decode correctly. Have a migration plan if you need to change the salt.

### Hex Encoding Features (Experimental) {#hex-encoding-features-experimental}

EncodedId includes experimental support for encoding hex strings, which can be useful for UUIDs and other hex-based identifiers.

#### Encoding UUIDs

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")

# Encode a UUID (hyphens are automatically stripped from input)
uuid = "9a566b8b-8618-42ab-8db7-a5a0276401fd"
encoded = coder.encode_hex(uuid)
# => "q66d-1429-0v59-qug7-35fv-9mys-kx58-ujvr-mfq6-av"

# Decode back to UUID (output does not include hyphens)
decoded = coder.decode_hex(encoded)
# => ["9a566b8b861842ab8db7a5a0276401fd"]
```

#### Optimizing Hex Encoding Length

For long hex strings like UUIDs, you can customize the `hex_digit_encoding_group_size` to get shorter encoded strings:

```ruby
# Default hex_digit_encoding_group_size (4)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
encoded = coder.encode_hex("9a566b8b861842ab8db7a5a0276401fd")
# => "q66d-1429-0v59-qug7-35fv-9mys-kx58-ujvr-mfq6-av"

# Larger group size for shorter output
coder = EncodedId::ReversibleId.hashid(
  salt: "my-salt",
  hex_digit_encoding_group_size: 32
)
encoded = coder.encode_hex("9a566b8b861842ab8db7a5a0276401fd")
# => "3352-63wk-2mx8-vj7g-m363-6zze-7rzw-m9"
```
