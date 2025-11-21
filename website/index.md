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

`encoded_id` is a Ruby gem that lets you encode numerical or hex IDs into obfuscated strings that can be used in URLs. These encoded IDs are reversible, meaning they can be decoded back to the original values.

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
# Using Hashids encoder (requires salt)
coder = EncodedId::ReversibleId.hashid(salt: "my-salt")
coder.encode(123)
# => "m3pm-8anj"

# Encoded strings are reversible
coder.decode("m3pm-8anj")
# => [123]

# Encode multiple IDs at once
coder.encode([78, 45])
# => "ny9y-sd7p"

# Using Sqids encoder (default, no salt required)
sqids_coder = EncodedId::ReversibleId.sqids
sqids_coder.encode(123)
# => (output varies)

# With Rails integration
class User < ApplicationRecord
  include EncodedId::Rails::Model

  def name_for_encoded_id_slug
    full_name
  end
end

# Find by encoded ID
user = User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
user.encoded_id                              # => "user_p5w9-z27j"
user.slugged_encoded_id                      # => "john-doe--user_p5w9-z27j"
```

## Key Features

### EncodedId Core

- 🔄 **Reversible** - Encoded IDs can be decoded back to original values
- 👥 **Multiple IDs** - Encode multiple numeric IDs in one string
- 🚀 **Choose your encoding** - Supports Sqids (default) and Hashids encoders
- 👓 **Human-readable** - Character grouping & mappings for easily confused characters
- 🔡 **Custom alphabets** - Use your preferred character set
- 🚗 **Performance** - Optimized Hashids encoder with better performance and less memory usage
- 🤬 **Blocklist filtering** - Built-in word blocklist support with configurable modes

### Rails Integration

- 🏷️ **ActiveRecord integration** - Use with ActiveRecord models
- 🔑 **Per-model configuration** - Custom salt and encoding settings per model
- 💅 **Slugged IDs** - URL-friendly slugs like `my-product--p5w9-z27j`
- 🔖 **Annotated IDs** - Model type indicators like `user_p5w9-z27j`
- 🔍 **Finder methods** - `find_by_encoded_id`, `where_encoded_id`, and more
- 🛣️ **URL params** - `to_param` automatically uses encoded IDs
- 🔒 **Safe defaults** - Limits on encoded ID lengths to prevent CPU and memory-intensive operations
- 💾 **Persistence** - Optional database persistence for efficient lookups

## Installation

### Standalone Gem

```bash
# Add to Gemfile
bundle add encoded_id

# Or install directly
gem install encoded_id
```

### Rails Integration

```bash
# Add to Gemfile
bundle add encoded_id-rails

# Run the generator
rails g encoded_id:rails:install
```

## Security Note

**Encoded IDs are not secure**. They provide obfuscation, not encryption. Do not use them as a security mechanism. Always implement proper authorization checks in your application.

As of version 1.0.0, **Sqids is the default encoder**. Hashids is still supported but is officially deprecated by the Hashids project in favor of Sqids.

Read more: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/) (applies to Hashids encoder)

## High Performance

EncodedId uses an optimized HashId implementation that significantly outperforms the original `hashids` gem:

- Up to **4x faster** with YJIT enabled
- Up to **98% reduction** in memory allocation
- Optimized for both speed and memory usage

See [benchmarks](/docs/encoded_id/benchmarks) for detailed performance comparisons.

## Getting Started

Explore the documentation to learn more:

- [EncodedId Core Guide](/docs/encoded_id/) - Installation, configuration, examples, and advanced topics
- [EncodedId Rails Guide](/docs/encoded_id_rails/) - Rails integration, configuration, and examples
- [Comparison to Similar Gems](/docs/similar-gems/) - How EncodedId compares to alternatives

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