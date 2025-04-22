---
layout: default
title: Examples
parent: EncodedId::Rails
nav_order: 4
---

# Examples

This page provides various examples of using EncodedId::Rails in different scenarios.

## Basic Usage

### Including in a Model

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end
```

### Encoding and Decoding IDs

```ruby
# Create a user
user = User.create(name: "John Doe")

# Get the encoded ID
user.encoded_id
# => "user_p5w9-z27j"

# Find by encoded ID
User.find_by_encoded_id("user_p5w9-z27j")
# => #<User id: 1, name: "John Doe">

# Works with just the hash part too
User.find_by_encoded_id("p5w9-z27j")
# => #<User id: 1, name: "John Doe">

# Find by encoded ID (raises if not found)
User.find_by_encoded_id!("user_p5w9-z27j")
# => #<User id: 1, name: "John Doe">

# Encode a specific ID
User.encode_encoded_id(123)
# => "p5w9-z27j"

# Decode an encoded ID
User.decode_encoded_id("user_p5w9-z27j")
# => [1]
```

## URL Helpers with Encoded IDs

### Using PathParam

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam
end

# Then in routes
# resources :users

user = User.create(name: "John Doe")

# URL helpers will use encoded ID
Rails.application.routes.url_helpers.user_path(user)
# => "/users/user_p5w9-z27j"
```

### Using SluggedPathParam

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  
  def name_for_encoded_id_slug
    name.parameterize
  end
end

user = User.create(name: "John Doe")

# URL helpers will use slugged encoded ID
Rails.application.routes.url_helpers.user_path(user)
# => "/users/john-doe--user_p5w9-z27j"
```

## Routes and Controllers

```ruby
# In routes.rb
Rails.application.routes.draw do
  resources :users, param: :encoded_id
end

# In UsersController
class UsersController < ApplicationController
  def show
    @user = User.find_by_encoded_id!(params[:encoded_id])
    # Now @user contains the user found by encoded ID
  end
end
```

## Custom Annotations

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def annotation_for_encoded_id
    "usr"  # Custom annotation prefix
  end
end

user = User.create(name: "John Doe")
user.encoded_id
# => "usr_p5w9-z27j"
```

## Persisting Encoded IDs

First, generate the migration:

```bash
rails generate encoded_id:rails:add_columns User
```

Then include the Persists module:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end

# Create a user
user = User.create(name: "John Doe")

# Get the persisted encoded IDs
user.normalized_encoded_id  # => "p5w9z27j" (without formatting)
user.prefixed_encoded_id    # => "user_p5w9-z27j" (with annotation)

# Query by normalized encoded ID
User.where(normalized_encoded_id: "p5w9z27j").first
# => #<User id: 1, name: "John Doe">
```

## Using the Sqids Encoder

First, add the sqids gem to your Gemfile:

```ruby
# In your Gemfile
gem 'sqids'
```

Then configure EncodedId::Rails to use Sqids:

```ruby
# In config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  config.salt = "your-application-salt"
  config.encoder = :sqids  # Use Sqids instead of HashIds
end

# In your model
class User < ApplicationRecord
  include EncodedId::Rails::Model
end

# Now encoded IDs will use Sqids
user = User.create(name: "John Doe")
user.encoded_id
# => "user_k6jR-8Myo"  # Different from HashIds encoding

# Finding works the same way
User.find_by_encoded_id("user_k6jR-8Myo")
# => #<User id: 1, name: "John Doe">
```

## Per-Model Encoder Configuration

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  
  # Override the encoded_id_coder method to use a different encoder for this model
  def self.encoded_id_coder(options = {})
    super(options.merge(encoder: :sqids))
  end
end

# Now Product models will use Sqids regardless of global configuration
product = Product.create(name: "Example Product")
product.encoded_id
# => "product_k6jR-8Myo"  # Uses Sqids

# But User models will use the global configuration
user = User.create(name: "John Doe")
user.encoded_id
# => "user_p5w9-z27j"  # Uses HashIds (if that's the global config)
```

## Blocklist Configuration

### Global Blocklist

```ruby
# In config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  config.salt = "your-application-salt"
  config.blocklist = ["bad", "word", "offensive"]
end
```

### Per-Model Blocklist

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  
  # Override the encoded_id_coder method to use a custom blocklist
  def self.encoded_id_coder(options = {})
    super(options.merge(blocklist: ["product", "item"]))
  end
end
```

## Seamless ActiveRecord Integration

The ActiveRecord module allows you to use encoded IDs with standard ActiveRecord finder methods:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecord
end

# Create a product
product = Product.create(name: "Example Product")
encoded_id = product.encoded_id  # => "product_p5w9-z27j"

# Now you can use standard ActiveRecord methods with encoded IDs
Product.find(encoded_id)           # => #<Product id: 1, name: "Example Product">
Product.find_by_id(encoded_id)     # => #<Product id: 1, name: "Example Product">
Product.where(id: encoded_id)      # => #<ActiveRecord::Relation [#<Product id: 1>]>

# It will still work with regular IDs too
Product.find(1)                    # => #<Product id: 1, name: "Example Product">

# And with multiple IDs
multiple_encoded_id = Product.encode_encoded_id([1, 2, 3])
Product.find(multiple_encoded_id)  # => [#<Product id: 1>, #<Product id: 2>, #<Product id: 3>]
```

### In Controllers

```ruby
class ProductsController < ApplicationController
  # Your model must include EncodedId::Rails::ActiveRecord
  def show
    # Works with both numeric IDs and encoded IDs
    @product = Product.find(params[:id])
  end
  
  def bulk_update
    # Works with an encoded ID containing multiple IDs
    @products = Product.find(params[:ids])
    # Process @products...
  end
end
```

**Important**: This module should NOT be used with models that use string-based primary keys (e.g., UUIDs).

## Combining Multiple Features

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  include EncodedId::Rails::Persists
  include EncodedId::Rails::ActiveRecord
  
  def name_for_encoded_id_slug
    name.parameterize
  end
  
  def self.encoded_id_coder(options = {})
    super(options.merge(
      encoder: :sqids,
      blocklist: ["offensive", "words"],
      id_length: 10
    ))
  end
end

# Now you have:
# 1. Slugged, encoded IDs in URLs
# 2. Persisted encoded IDs for efficient lookups
# 3. Seamless ActiveRecord integration
# 4. Custom encoder (Sqids)
# 5. Custom blocklist
# 6. Custom ID length
```