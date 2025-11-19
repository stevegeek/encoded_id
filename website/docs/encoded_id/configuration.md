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

### Minimum Length

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

### Maximum Length

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

### Maximum Inputs Per ID

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

### Encoder (Algorithm) {#encoder-algorithm}

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

### Blocklist {#blocklist}

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

#### Built-in Blocklists

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

#### Blocklist Modes

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

#### Blocklist Max Length

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

## Formatting Options {#formatting-options}

### Split At

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

### Split With

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

## Alphabet Customization {#alphabet-customization}

### Using a Custom Alphabet

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

### Character Equivalences

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

## Hex Encoding Options (Experimental)

### Hex Digit Encoding Group Size

The `hex_digit_encoding_group_size` parameter controls how hex strings are encoded (default: 4). Must be between 1 and 32.

```ruby
# With Hashids
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", hex_digit_encoding_group_size: 32)

# With Sqids
coder = EncodedId::ReversibleId.sqids(hex_digit_encoding_group_size: 32)
```

Larger values produce shorter encoded strings for long inputs (e.g., UUIDs). See [Hex Encoding Features](advanced-topics.html#hex-encoding-features-experimental) for detailed examples and optimization guidance.