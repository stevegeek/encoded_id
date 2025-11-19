---
layout: default
title: Examples
parent: EncodedId
nav_order: 4
---

# Examples
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

2. This page provides various examples of using EncodedId in different scenarios.

## Basic Usage

### Encoding and Decoding Simple IDs

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

### Encoding and Decoding Multiple IDs

```ruby
coder = EncodedId::ReversibleId.hashid(salt: "my-secret-salt")

# Encode multiple IDs
encoded = coder.encode([78, 45, 92])
# => "qfxs-b2xe-b"

# Decode back to the original IDs
decoded = coder.decode(encoded)
# => [78, 45, 92]
```

### Character Case Resilience

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

## Using Different Encoders

### Sqids Encoder (Default)

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

### Hashids Encoder

To use the Hashids encoder:

```ruby
# Hashids requires a salt
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"
```

See [Encoder Configuration](configuration.html#encoder-algorithm) for setup requirements and encoder options.

## Blocklist Support

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

See [Blocklist Configuration](configuration.html#blocklist) for detailed behavior and options.

## Formatting Options

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

See [Formatting Options](configuration.html#formatting-options) for detailed configuration options.

## Custom Alphabets

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

See [Alphabet Customization](configuration.html#alphabet-customization) for more alphabet options and built-in alphabets.

## Advanced Options

### Setting Minimum Length

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

### Setting Maximum Length

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

### Limiting Maximum Inputs

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

## Experimental: Hex Encoding

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

See [Hex Encoding Features](advanced-topics.html#hex-encoding-features-experimental) for UUID optimization and detailed examples.