---
layout: default
title: EncodedId::Rails
nav_order: 3
has_children: true
permalink: /docs/encoded_id_rails/
---

# EncodedId::Rails

`encoded_id-rails` is a gem that provides Rails integration for `encoded_id`, making it easy to use encoded IDs with your ActiveRecord models.

## Why use EncodedId::Rails?

- **Obfuscate database IDs in URLs**: Hide sequential numeric IDs from users
- **Human-friendly URLs**: Generate readable, user-friendly URLs for your resources
- **Slugged IDs**: Combine human-readable names with encoded IDs (e.g., `/users/bob-smith--usr_p5w9-z27j`)
- **Annotated IDs**: Include model information in encoded IDs (e.g., `user_p5w9-z27j`)
- **Finder methods**: Find ActiveRecord models using encoded IDs
- **Automatic URL generation**: Override `to_param` to use encoded IDs in URL helpers
- **Persistence**: Optionally store encoded IDs in the database for efficient lookups

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'encoded_id-rails'
```

And then execute:

```bash
bundle install
```

Then run the installation generator:

```bash
rails generate encoded_id:rails:install
```

This will create a configuration file at `config/initializers/encoded_id.rb`.

## Quick Start

```ruby
# Include in your model
class User < ApplicationRecord
  include EncodedId::Rails::Model
end

# Create a user
user = User.create(name: "John Doe")

# Get the encoded ID
user.encoded_id
# => "user_p5w9-z27j"

# Get a slugged version (if you implement name_for_encoded_id_slug)
user.slugged_encoded_id 
# => "john-doe--user_p5w9-z27j"

# Find a user by encoded ID
User.find_by_encoded_id("user_p5w9-z27j")
# => #<User id: 123, name: "John Doe">

# Find by just the hash part (without model annotation)
User.find_by_encoded_id("p5w9-z27j")
# => #<User id: 123, name: "John Doe">

# Find by slugged version too
User.find_by_encoded_id("john-doe--user_p5w9-z27j")
# => #<User id: 123, name: "John Doe">
```

## Using in Routes

```ruby
# In config/routes.rb
Rails.application.routes.draw do
  resources :users, param: :encoded_id
end

# In your controller
class UsersController < ApplicationController
  def show
    @user = User.find_by_encoded_id!(params[:encoded_id])
  end
end

# In your views, URL helpers will use encoded IDs
link_to "View User", user_path(user)
# => "/users/user_p5w9-z27j"
```

## Optional Path Parameter Modules

To automatically use encoded IDs in URL helpers, include one of these modules:

```ruby
# Use encoded IDs in URL helpers
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam
end

# Or use slugged encoded IDs in URL helpers
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  
  def name_for_encoded_id_slug
    full_name
  end
end
```

This will override `to_param` to return the encoded ID or slugged encoded ID, making URL helpers automatically use encoded IDs.

## Optional Persistence Module

For better performance with frequent encoded ID lookups, you can persist encoded IDs:

```bash
# Generate migration for User model
rails generate encoded_id:rails:add_columns User
```

Then include the persistence module:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end
```

## Optional ActiveRecord Integration

For seamless integration with standard ActiveRecord finder methods, include `ActiveRecordFinders`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecordFinders
end

# Standard ActiveRecord methods now work with encoded IDs
Product.find("product_p5w9-z27j")      # => #<Product id: 1>
Product.where(id: "product_p5w9-z27j") # => #<ActiveRecord::Relation>
```

**Important**: Do NOT use with string-based primary keys (e.g., UUIDs).

See [ActiveRecordFinders API](api.md#encodeididrailsactiverecordfinders) for all supported methods and detailed examples.

## Features in Detail

* 🔄 Encoded IDs are reversible (supports both HashIds and Sqids encoding engines)
* 💅 Support for slugged IDs that are URL friendly
* 🔖 Annotated IDs to help identify the model
* 👓 Human-readable IDs split into groups
* 👥 Support for multiple IDs encoded in one string
* 🛡️ Blocklist support to prevent certain words in encoded IDs
* 🔄 Seamless ActiveRecord integration for transparent handling of encoded IDs