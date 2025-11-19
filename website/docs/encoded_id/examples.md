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
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode a single ID
encoded = coder.encode(123)
# => "p5w9-z27j"

# Decode back to the original ID
decoded = coder.decode(encoded)
# => [123]

# The first element is our original ID
decoded.first
# => 123
```

### Encoding and Decoding Multiple IDs

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode multiple IDs
encoded = coder.encode([78, 45, 92])
# => "z2j7-0dmw-kf8p"

# Decode back to the original IDs
decoded = coder.decode(encoded)
# => [78, 45, 92]
```

### Character Case Resilience

EncodedId is resilient to character case differences:

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode an ID
encoded = coder.encode(123)
# => "p5w9-z27j"

# Decode even with uppercase letters
coder.decode("P5W9-Z27J")
# => [123]

# Disable case conversion if needed (for case-sensitive encodings)
coder.decode("p5w9-z27j", downcase: false)
# => [123]
```

## Using Different Encoders

### HashIds Encoder (Default)

```ruby
# The default encoder is HashIds
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode using HashIds
encoded = coder.encode(123)
# => "p5w9-z27j"
```

### Sqids Encoder

To use the Sqids encoder instead of the default HashIds:

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-salt", encoder: :sqids)
coder.encode(123)  # => "k6jR-8Myo"
```

See [Encoder Configuration](configuration.md#encoder-algorithm) for setup requirements and encoder options.

## Blocklist Support

Prevent specific words from appearing in encoded IDs. Behavior differs by encoder - HashIds raises errors while Sqids automatically avoids blocklisted words.

```ruby
# HashIds: raises error if blocklisted word appears
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  encoder: :hashids,
  blocklist: ["bad", "word"]
)

begin
  coder.encode(12345)
rescue EncodedId::InvalidInputError => e
  puts e.message  # => Generated ID contains blocklisted word
end

# Sqids: automatically avoids blocklisted words
coder = EncodedId::ReversibleId.new(
  salt: "my-salt",
  encoder: :sqids,
  blocklist: ["bad", "word"]
)
coder.encode(12345)  # => Safe ID without blocklisted words
```

See [Blocklist Configuration](configuration.md#blocklist) for detailed behavior and options.

## Formatting Options

Customize how encoded IDs are formatted:

```ruby
# Custom separator and group size
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_at: 3, split_with: ".")
coder.encode(123)  # => "p5w.9z2.7j"

# Disable grouping
coder = EncodedId::ReversibleId.new(salt: "my-salt", split_at: nil)
coder.encode(123)  # => "p5w9z27j"
```

See [Formatting Options](configuration.md#formatting-options) for detailed configuration options.

## Custom Alphabets

Use custom character sets for encoding:

```ruby
# Hexadecimal alphabet
hex_alphabet = EncodedId::Alphabet.new("0123456789abcdef")
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: hex_alphabet)
coder.encode(123)  # => "d783-ca9d"

# With character equivalences (e.g., lowercase maps to uppercase)
alphabet = EncodedId::Alphabet.new("0123456789ABCDEF", {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"})
coder = EncodedId::ReversibleId.new(salt: "my-salt", alphabet: alphabet)
coder.encode(123)  # => "D783-CA9D"
coder.decode("d783-ca9d")  # => [123]
```

See [Alphabet Customization](configuration.md#alphabet-customization) for more alphabet options and built-in alphabets.

## Advanced Options

### Setting Minimum Length

```ruby
# Set minimum length to 12 characters
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  length: 12
)

encoded = coder.encode(123)
# => "00p5-w9z2-7j00"
```

### Setting Maximum Length

```ruby
# Set maximum length to 16 characters
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  max_length: 16
)

# This will work fine
encoded = coder.encode(123)
# => "p5w9-z27j"

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
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  max_inputs_per_id: 5
)

# This works fine
encoded = coder.encode([1, 2, 3, 4, 5])
# => "71nd-39fe-k"

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
coder = EncodedId::ReversibleId.new(salt: "my-salt")
encoded = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "5jjy-c8d9-hxp2-qsve-rgh9-rxnt-7nb5-tve7-bf84-vr"

coder.decode_hex(encoded)
# => ["9a566b8b-8618-42ab-8db7-a5a0276401fd"]
```

See [Hex Encoding Features](../advanced-topics.md#hex-encoding-features-experimental) for UUID optimization and detailed examples.