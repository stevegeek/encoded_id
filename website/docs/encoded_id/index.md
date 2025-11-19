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

See [Encoder Configuration](configuration.html#encoder-algorithm) for details on encoder options, performance characteristics, and gem requirements.

## Blocklist Support

Prevent specific words from appearing in encoded IDs:

```ruby
# With Hashids
coder = EncodedId::ReversibleId.hashid(salt: "my-salt", blocklist: ["bad", "word"])

# With Sqids (uses blocklist for alphabet shuffling)
coder = EncodedId::ReversibleId.sqids(blocklist: ["bad", "word"])
```

See [Blocklist Configuration](configuration.html#blocklist) for details on encoder-specific behavior.

## Security Note

**Encoded IDs are not secure**. It may be possible to reverse them via brute-force. They are meant to be used in URLs as an obfuscation. The algorithm is not an encryption.

As of version 1.0.0, **Sqids is the default encoder**. Hashids is still supported but is officially deprecated by the Hashids project in favor of Sqids.

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/) (note: this specifically applies to the Hashids encoder)

For more details, please refer to:
- [Sqids](https://sqids.org/) (Default)
- [Hashids](https://hashids.org/) (Deprecated)
