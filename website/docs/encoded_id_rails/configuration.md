---
layout: default
title: Configuration
parent: EncodedId::Rails
nav_order: 3
---

# Configuration
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

The EncodedId Rails integration can be configured in `config/initializers/encoded_id.rb`. This file is created when you run the installation generator:

```bash
rails generate encoded_id:rails:install
```

## Configuration Options

```ruby
# config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  # Required: Salt used for encoding. Should be unique to your application
  config.salt = "your-application-salt"

  # Optional: Length of the encoded ID (minimum, default: 8)
  config.id_length = 8

  # Optional: Split the encoded ID every X characters (default: 4)
  config.character_group_size = 4

  # Optional: Character to use for splitting (default: "-")
  config.group_separator = "-"

  # Optional: Alphabet to use for encoding
  config.alphabet = EncodedId::Alphabet.modified_crockford

  # Optional: Method to call for annotation prefix (default: :annotation_for_encoded_id)
  config.annotation_method_name = :annotation_for_encoded_id

  # Optional: Separator between annotation and ID (default: "_")
  config.annotated_id_separator = "_"

  # Optional: Method to call for slug value (default: :name_for_encoded_id_slug)
  config.slug_value_method_name = :name_for_encoded_id_slug

  # Optional: Separator between slug and ID (default: "--")
  config.slugged_id_separator = "--"

  # Optional: Whether models should override to_param by default (default: false)
  config.model_to_param_returns_encoded_id = false

  # Optional: Encoder to use (default: :hashids)
  config.encoder = :hashids

  # Optional: Blocklist of words to prevent in encoded IDs (default: nil)
  config.blocklist = nil

  # Optional: For hex encoding, experimental (default: 4)
  config.hex_digit_encoding_group_size = 4
end
```

## Salt Configuration

### Global Salt

The easiest way to configure the salt is to set it globally:

```ruby
EncodedId::Rails.configure do |config|
  config.salt = "your-application-salt"
end
```

This salt will be used by all models unless they specify their own salt.

### Per-Model Salt

You can also configure the salt per model by overriding the `encoded_id_salt` method:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def self.encoded_id_salt
    "user-specific-salt"
  end
end
```

This allows you to use different salts for different models, which can be useful in multi-tenant applications or when you want to change the salt for a specific model without affecting others.

## Encoder Configuration {#encoder}

EncodedId supports two encoding algorithms: HashIds (default) and Sqids. You can configure which one to use globally:

```ruby
EncodedId::Rails.configure do |config|
  # Use Sqids encoder
  config.encoder = :sqids
end
```

To use the Sqids encoder, you need to add the 'sqids' gem to your Gemfile:

```ruby
gem 'sqids'
```

If you attempt to use the Sqids encoder without the gem installed, an error will be raised.

### Per-Model Encoder

You can also configure the encoder on a per-model basis by overriding the `encoded_id_coder` method:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  
  def self.encoded_id_coder(options = {})
    super(options.merge(encoder: :sqids))
  end
end
```

**Important**: HashIds and Sqids encoders are not compatible. Don't switch encoders after your application is in production as existing encoded IDs will no longer decode correctly.

## Blocklist Configuration

You can configure a blocklist of words that should not appear in generated IDs:

```ruby
EncodedId::Rails.configure do |config|
  config.blocklist = ["bad", "word", "offensive"]
end
```

The behavior differs depending on the encoder:

- For HashIds: An error will be raised if a generated ID contains a blocklisted word.
- For Sqids: The algorithm automatically avoids generating IDs with blocklisted words.

### Per-Model Blocklist

You can also configure the blocklist on a per-model basis:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  
  def self.encoded_id_coder(options = {})
    super(options.merge(blocklist: ["product", "item"]))
  end
end
```

## Annotation Configuration

The annotation is a prefix added to encoded IDs to help identify which model they belong to.

### Default Annotation

By default, models use their underscored class name as the annotation:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end

user = User.create
user.encoded_id  # => "user_p5w9-z27j"
```

### Custom Annotation

You can customize the annotation by overriding the `annotation_for_encoded_id` method:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def annotation_for_encoded_id
    "usr"
  end
end

user = User.create
user.encoded_id  # => "usr_p5w9-z27j"
```

### Disable Annotation

To disable annotation completely, set the `annotation_method_name` to `nil`:

```ruby
EncodedId::Rails.configure do |config|
  config.annotation_method_name = nil
end

# Or override the method to return nil
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def annotation_for_encoded_id
    nil
  end
end

user = User.create
user.encoded_id  # => "p5w9-z27j" (no annotation)
```

## Slug Configuration

Slugs are human-readable prefixes added to encoded IDs to make URLs more user-friendly.

### Adding Slugs

To use slugs, you must implement the `name_for_encoded_id_slug` method:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def name_for_encoded_id_slug
    username.parameterize
  end
end

user = User.create(username: "John Doe")
user.slugged_encoded_id  # => "john-doe--user_p5w9-z27j"
```

### Custom Slug Method

You can change the method used for generating slugs globally:

```ruby
EncodedId::Rails.configure do |config|
  config.slug_value_method_name = :custom_slug_method
end

class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def custom_slug_method
    "#{role}-#{username}".parameterize
  end
end
```

### Slug Separator

You can customize the separator between the slug and the encoded ID:

```ruby
EncodedId::Rails.configure do |config|
  config.slugged_id_separator = "_"
end

user = User.create(username: "John Doe")
user.slugged_encoded_id  # => "john-doe_user_p5w9-z27j"
```

## URL Parameter Configuration

By default, models don't override `to_param`. You can enable this for all models:

```ruby
EncodedId::Rails.configure do |config|
  config.model_to_param_returns_encoded_id = true
end
```

Or include the appropriate module in specific models:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam
end

# Or for slugged IDs
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  
  def name_for_encoded_id_slug
    title.parameterize
  end
end
```

## Alphabet Configuration

You can customize the alphabet used for encoding:

```ruby
EncodedId::Rails.configure do |config|
  # Use URL-safe Base64 alphabet
  config.alphabet = EncodedId::Alphabet.new(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  )
  
  # Or a shorter alphabet with equivalents for confused characters
  config.alphabet = EncodedId::Alphabet.new(
    "0123456789ABCDEF",
    {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E", "f" => "F"}
  )
end
```

## Formatting Configuration

You can customize how encoded IDs are formatted:

```ruby
EncodedId::Rails.configure do |config|
  # No grouping
  config.character_group_size = nil
  
  # Or custom grouping
  config.character_group_size = 3
  config.group_separator = "."
end
```

This affects how the encoded ID appears in URLs and when displayed.