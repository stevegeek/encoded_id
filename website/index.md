---
layout: home
title: Introduction
nav_order: 1
permalink: /
---

# `EncodedId` and `EncodedId::Rails`
{: .fs-9 }

Customizable ID obfuscation for Ruby and Rails
{: .fs-6 .fw-300 }

## What are these gems?

`encoded_id` is a zero-dependency Ruby gem that lets you encode numerical or hex IDs into obfuscated strings that can be used in URLs. These encoded IDs are reversible, meaning they can be decoded back to the original values.

`encoded_id-rails` integrates EncodedId with Rails and ActiveRecord models, providing a way to use encoded IDs in your Rails applications.

## Why use EncodedId?

- **Hide database IDs**: Obfuscate sequential database IDs to avoid exposing internal record counts
- **Friendly URLs**: Create user-friendly, readable URLs while maintaining the ability to decode
- **URL customization**: Add human-readable slugs, prefixes, and formatting
- **Multiple ID encoding**: Encode multiple IDs into a single string
- **Safe defaults**: Limits on encoded ID lengths to prevent CPU and memory-intensive encode/decodes
- **Flexible configuration**: Customize alphabet, length, and formatting

## Quick Example

```ruby
# Basic encoding and decoding
coder = EncodedId::ReversibleId.new(salt: "my-secret-salt")
coder.encode(123)                # => "p5w9-z27j"
coder.decode("p5w9-z27j")        # => [123]

# Encode multiple IDs
coder.encode([78, 45])           # => "z2j7-0dmw"
coder.decode("z2j7-0dmw")        # => [78, 45]

# With Rails integration
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  
  def name_for_encoded_id_slug
    full_name
  end
end

user = User.create(full_name: "John Doe")
user.encoded_id                  # => "user_p5w9-z27j"
user.slugged_encoded_id          # => "john-doe--user_p5w9-z27j"
User.find_by_encoded_id("user_p5w9-z27j")  # => #<User id: 123>
```

## Core Features

### EncodedId

- 🔄 Reversible encoding based on an improved Hashids implementation
- 👥 Support for encoding multiple IDs in one string
- 🔡 Customizable alphabets with at least 16 characters
- 👓 Character mapping for easily confused characters (e.g., 0/O, 1/I/l)
- 🤬 Built-in profanity filtering
- 🤓 Optional grouping of characters for improved readability
- 🥽 Configurable length limits for security

### EncodedId::Rails

- 💅 Slugged IDs for URL-friendly representations (e.g., `my-product--p5w9-z27j`)
- 🔖 Annotated IDs to identify model types (e.g., `user_p5w9-z27j`)
- 🔍 Finder methods to look up records by encoded IDs
- 🚦 ActiveRecord integration with model mixins
- 💾 Optional database persistence for efficient lookups

## High Performance

EncodedId uses a custom HashId implementation that is significantly faster and more memory-efficient than the original `hashids` gem:

- Up to **4x faster** with YJIT enabled
- Up to **98% reduction** in memory allocation
- Optimized for both speed and memory usage

## Getting Started

Explore the documentation to learn more about each gem:

- [EncodedId Documentation](/docs/encoded_id/)
- [EncodedId::Rails Documentation](/docs/encoded_id_rails/)
- [Similar Gems](/docs/similar-gems/)

## Project Goals

- Provide a high-performance, memory-efficient implementation of reversible ID encoding
- Create a seamless integration with Rails and ActiveRecord
- Offer extensive customization options for different use cases
- Maintain excellent documentation and test coverage

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/stevegeek/encoded_id](https://github.com/stevegeek/encoded_id).

EncodedId is maintained by [stevegeek](https://github.com/stevegeek) and other contributors.

## License

EncodedId is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).