---
layout: default
title: Examples
parent: EncodedId
nav_order: 4
---

# Examples

This page provides various examples of using EncodedId in different scenarios.

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

To use the Sqids encoder, you need to add the 'sqids' gem to your Gemfile:

```ruby
# In your Gemfile
gem 'sqids'
```

Then you can use it like this:

```ruby
# Create an instance with the Sqids encoder
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  encoder: :sqids
)

# Encode using Sqids
encoded = coder.encode(123)
# => "k6jR-8Myo"

# Decode works the same way
coder.decode("k6jR-8Myo")
# => [123]
```

**Important**: HashIds and Sqids are not compatible with each other. Choose one encoder and stick with it, as they will generate different encoded IDs for the same inputs.

## Blocklist Support

### Blocklist with HashIds

```ruby
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  encoder: :hashids,
  blocklist: ["bad", "word", "offensive"]
)

# If an encoded ID contains a blocklisted word, the encoder will raise an error
begin
  encoded = coder.encode(12345)
  puts "Encoded: #{encoded}"
rescue EncodedId::InvalidInputError => e
  puts "Error: #{e.message}"
  # => Error: Generated ID contains blocklisted word: 'bad'
end
```

### Blocklist with Sqids

```ruby
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  encoder: :sqids,
  blocklist: ["bad", "word", "offensive"]
)

# Sqids automatically avoids generating IDs with blocklisted words
encoded = coder.encode(12345)
# => "Uk32-7Ewo"  # ID is guaranteed not to contain any blocklisted words
```

## Formatting Options

### Customizing the Separator and Group Size

```ruby
# Change the separator and group size
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  split_at: 3,       # Group every 3 characters
  split_with: "."    # Use a dot as separator
)

encoded = coder.encode(123)
# => "p5w.9z2.7j"
```

### Disabling Grouping

```ruby
# Disable grouping completely
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  split_at: nil     # Disable grouping
)

encoded = coder.encode(123)
# => "p5w9z27j"

# Alternative way to disable grouping
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  split_with: nil   # Disable grouping
)

encoded = coder.encode(123)
# => "p5w9z27j"
```

## Custom Alphabets

### Using a Custom Alphabet

```ruby
# Create a custom alphabet
hex_alphabet = EncodedId::Alphabet.new("0123456789abcdef")

coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  alphabet: hex_alphabet
)

encoded = coder.encode(123)
# => "d783-ca9d"
```

### Alphabet with Character Equivalences

```ruby
# Custom alphabet with equivalences for easily confused characters
alphabet = EncodedId::Alphabet.new(
  "0123456789ABCDEF",  # Uppercase hexadecimal
  {
    "a" => "A",        # Map lowercase to uppercase
    "b" => "B",
    "c" => "C",
    "d" => "D",
    "e" => "E",
    "f" => "F"
  }
)

coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  alphabet: alphabet
)

encoded = coder.encode(123)
# => "D783-CA9D"

# Will be able to decode even with lowercase letters
coder.decode("d783-ca9d")
# => [123]
```

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

```ruby
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode a hex string
encoded = coder.encode_hex("10f8c")
# => "w72a-y0az"

# Decode back to the original hex string
coder.decode_hex(encoded)
# => ["10f8c"]

# Encoding UUIDs
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  hex_digit_encoding_group_size: 32  # Larger group size for shorter output
)
encoded = coder.encode_hex("9a566b8b-8618-42ab-8db7-a5a0276401fd")
# => "vr7m-qra8-m5y6-dkgj-5rqr-q44e-gp4a-52"

# Decode back to the original UUID
coder.decode_hex(encoded)
# => ["9a566b8b-8618-42ab-8db7-a5a0276401fd"]
```