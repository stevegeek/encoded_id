---
layout: default
title: EncodedId
nav_order: 2
has_children: true
permalink: /docs/encoded_id/
---

# EncodedId

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

```ruby
# Create an instance with your own secret salt
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")

# Encode a numeric ID
encoded = coder.encode(123)
# => "p5w9-z27j"

# Decode back to the original ID
coder.decode("p5w9-z27j")
# => [123]

# Encode multiple IDs at once
coder.encode([78, 45])
# => "z2j7-0dmw"

# Decode multiple IDs
coder.decode("z2j7-0dmw")
# => [78, 45]
```

## Using Sqids Instead of HashIds

```ruby
# First add the gem to your Gemfile
# gem 'sqids'

# Then create an instance with the Sqids encoder
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  encoder: :sqids
)

# Encoding and decoding work the same way
encoded = coder.encode(123)
# => "k6jR-8Myo"
coder.decode("k6jR-8Myo")
# => [123]
```

## Blocklist Support

```ruby
# Prevent offensive words in IDs
coder = EncodedId::ReversibleId.new(
  salt: "my-secret-salt",
  blocklist: ["bad", "word", "offensive"]
)

# With HashIds, raises an error if a blocklisted word is generated
# With Sqids, automatically avoids generating IDs with blocklisted words
```

## Security Note

**Encoded IDs are not secure**. It may be possible to reverse them via brute-force. They are meant to be used in URLs as an obfuscation. The algorithm is not an encryption.

For more details, please refer to:
- [Hashids](https://hashids.org/)
- [Sqids](https://sqids.org/)
