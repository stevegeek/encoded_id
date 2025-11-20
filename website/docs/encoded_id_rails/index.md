---
layout: default
title: EncodedId::Rails
nav_order: 3
has_children: true
permalink: /docs/encoded_id_rails/
---

# EncodedId::Rails
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

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

### Using in Routes

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

### Optional Path Parameter Modules

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

### Optional Persistence Module

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

### Optional ActiveRecord Integration

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

See [ActiveRecordFinders API](api.html#encodeididrailsactiverecordfinders) for all supported methods and detailed examples.

### Features in Detail

* 🔄 Encoded IDs are reversible (supports both HashIds and Sqids encoding engines)
* 💅 Support for slugged IDs that are URL friendly
* 🔖 Annotated IDs to help identify the model
* 👓 Human-readable IDs split into groups
* 👥 Support for multiple IDs encoded in one string
* 🛡️ Blocklist support to prevent certain words in encoded IDs
* 🔄 Seamless ActiveRecord integration for transparent handling of encoded IDs

## Configuration

The EncodedId Rails integration can be configured in `config/initializers/encoded_id.rb`. This file is created when you run the installation generator:

```bash
rails generate encoded_id:rails:install
```

### Configuration Options

```ruby
# config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  # Required for Hashids encoder: Salt used for encoding. Should be unique to your application
  # Not required for Sqids encoder (the default)
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

  # Optional: Encoder to use (default: :sqids, or :hashids for backwards compatibility)
  config.encoder = :sqids

  # Optional: Downcase input before decoding (default: false, set true for pre-v1 compatibility)
  config.downcase_on_decode = false

  # Optional: Blocklist of words to prevent in encoded IDs (default: Blocklist.empty)
  config.blocklist = EncodedId::Blocklist.empty

  # Optional: Blocklist mode - when to check for blocklisted words (default: :length_threshold)
  # Options: :length_threshold, :always, :raise_if_likely
  config.blocklist_mode = :length_threshold

  # Optional: Maximum length threshold for blocklist checking (default: 32)
  # Only relevant when blocklist_mode is :length_threshold
  config.blocklist_max_length = 32
end
```

**Note**: As of v1.0.0, the default encoder is `:sqids` and `downcase_on_decode` defaults to `false`.

### Salt Configuration

**Note**: Salt is only required when using the Hashids encoder. The default Sqids encoder does not use a salt parameter.

#### Global Salt

The easiest way to configure the salt is to set it globally:

```ruby
EncodedId::Rails.configure do |config|
  config.salt = "your-application-salt"
end
```

This salt will be used by all models unless they specify their own salt.

#### Per-Model Salt

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

### Encoder Configuration {#encoder}

EncodedId supports two encoding algorithms: Sqids (default) and HashIds. You can configure which one to use globally:

```ruby
EncodedId::Rails.configure do |config|
  # Use HashIds encoder for backwards compatibility
  config.encoder = :hashids
end
```

**Note**: As of v1.0.0, Sqids is the default encoder. The 'sqids' gem is a runtime dependency and is automatically included.

#### Per-Model Encoder

You can configure the encoder on a per-model basis using `encoded_id_config`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  # Use HashIds for this model specifically
  encoded_id_config encoder: :hashids
end
```

**Important**: HashIds and Sqids encoders are not compatible. Don't switch encoders after your application is in production as existing encoded IDs will no longer decode correctly.

### Blocklist Configuration

You can configure a blocklist of words that should not appear in generated IDs:

```ruby
EncodedId::Rails.configure do |config|
  # Custom blocklist
  config.blocklist = ["bad", "word", "offensive"]

  # Or use built-in blocklists
  config.blocklist = EncodedId::Blocklist.minimal  # 51 common words
  config.blocklist = EncodedId::Blocklist.sqids_blocklist  # 560 words
  config.blocklist = EncodedId::Blocklist.empty  # No filtering
end
```

The behavior differs depending on the encoder:

- For HashIds: An error will be raised if a generated ID contains a blocklisted word.
- For Sqids: The algorithm automatically avoids generating IDs with blocklisted words.

#### Blocklist Modes

You can configure blocklist modes globally or per-model to control when blocklist checking occurs:

##### Global Configuration

```ruby
EncodedId::Rails.configure do |config|
  config.blocklist = EncodedId::Blocklist.minimal
  config.blocklist_mode = :length_threshold  # Default
  config.blocklist_max_length = 32  # Default - only check IDs ≤ 32 characters
end
```

##### Per-Model Configuration

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  # Configure blocklist with custom mode
  encoded_id_config(
    blocklist: EncodedId::Blocklist.minimal,
    blocklist_mode: :always,  # Check all IDs regardless of length
    blocklist_max_length: 50  # Custom threshold (only relevant for :length_threshold mode)
  )
end
```

**Blocklist Modes:**
- `:length_threshold` (default) - Only check IDs ≤ `blocklist_max_length` (default: 32). Best performance for most use cases.
- `:always` - Check all IDs regardless of length. Use when you need maximum filtering.
- `:raise_if_likely` - Raise error during initialization if configuration likely causes performance issues. Use to catch misconfigurations in development.

See [EncodedId Blocklist Configuration](../encoded_id/index.html#blocklist) for detailed information about blocklist modes and performance implications.

#### Per-Model Blocklist

You can configure the blocklist on a per-model basis using `encoded_id_config`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  encoded_id_config blocklist: ["product", "item"]
end
```

### Annotation Configuration

The annotation is a prefix added to encoded IDs to help identify which model they belong to.

#### Default Annotation

By default, models use their underscored class name as the annotation:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end

user = User.create
user.encoded_id  # => "user_p5w9-z27j"
```

#### Custom Annotation

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

#### Disable Annotation

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

### Slug Configuration

Slugs are human-readable prefixes added to encoded IDs to make URLs more user-friendly.

#### Adding Slugs

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

#### Custom Slug Method

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

#### Slug Separator

You can customize the separator between the slug and the encoded ID:

```ruby
EncodedId::Rails.configure do |config|
  config.slugged_id_separator = "_"
end

user = User.create(username: "John Doe")
user.slugged_encoded_id  # => "john-doe_user_p5w9-z27j"
```

### URL Parameter Configuration

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

### Alphabet Configuration

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

### Formatting Configuration

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

## Examples

This section provides various examples of using EncodedId::Rails in different scenarios.

### Basic Usage

#### Including in a Model

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end
```

#### Encoding and Decoding IDs

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

### URL Helpers with Encoded IDs

#### Using PathParam

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

#### Using SluggedPathParam

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

### Routes and Controllers

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

### Custom Annotations

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

### Persisting Encoded IDs

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

### Encoder Configuration

By default, EncodedId::Rails uses Sqids encoding (as of v1.0.0):

```ruby
# Models use Sqids by default
user = User.create(name: "John Doe")
user.encoded_id  # => "user_k6jR-8Myo"
```

You can also configure EncodedId::Rails to use HashIds if you want:

```ruby
# In config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  config.encoder = :hashids
end

# Models now use HashIds encoding
user = User.create(name: "John Doe")
user.encoded_id  # => "user_p5w9-z27j"
```

See [Configuration](#encoder) for encoder options and requirements.

### Per-Model Encoder Configuration

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  # Configure to use HashIds for this model only
  encoded_id_config encoder: :hashids
end

# Now Product models will use HashIds regardless of global configuration
product = Product.create(name: "Example Product")
product.encoded_id
# => "product_p5w9-z27j"  # Uses HashIds

# But User models will use the global configuration (Sqids by default)
user = User.create(name: "John Doe")
user.encoded_id
# => "user_k6jR-8Myo"  # Uses Sqids (default)
```

### Blocklist Configuration

#### Global Blocklist

```ruby
# In config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  config.salt = "your-application-salt"
  config.blocklist = ["bad", "word", "offensive"]
end
```

#### Per-Model Blocklist

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  # Configure a custom blocklist for this model
  encoded_id_config blocklist: ["product", "item"]
end
```

### ActiveRecord Finder Integration

Use encoded IDs seamlessly with standard ActiveRecord methods by including `ActiveRecordFinders`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecordFinders
end

# Standard ActiveRecord methods work with encoded IDs
Product.find("product_p5w9-z27j")  # => #<Product id: 1>
Product.where(id: "product_p5w9-z27j")  # => #<ActiveRecord::Relation>

# In controllers
def show
  @product = Product.find(params[:id])  # Works with both IDs and encoded IDs
end
```

See [ActiveRecordFinders API](api.html#encodeididrailsactiverecordfinders) for all supported finder methods and detailed usage.

**Important**: This module should NOT be used with models that use string-based primary keys (e.g., UUIDs).

### Combining Multiple Features

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  include EncodedId::Rails::Persists
  include EncodedId::Rails::ActiveRecordFinders

  # Configure encoding options for this model
  encoded_id_config(
    blocklist: ["offensive", "words"],
    id_length: 10
  )

  def name_for_encoded_id_slug
    name.parameterize
  end
end

# Now you have:
# 1. Slugged, encoded IDs in URLs
# 2. Persisted encoded IDs for efficient lookups
# 3. Seamless ActiveRecord integration
# 4. Custom blocklist
# 5. Custom ID length
```

### Single Table Inheritance (STI) {#single-table-inheritance-sti}

When using EncodedId with Single Table Inheritance, you need to decide whether child classes should share the same salt as the parent.

By default, each class in an STI hierarchy has its own unique salt, making encoded IDs incompatible across classes. This section shows how to handle both scenarios.

#### Example 1: Default Behavior (Separate Salts)

By default, each class in an STI hierarchy has its own salt:

```ruby
class Vehicle < ApplicationRecord
  include EncodedId::Rails::Model
end

class Car < Vehicle
end

class Motorcycle < Vehicle
end

# Create vehicles
car = Car.create(make: "Toyota", model: "Camry")
motorcycle = Motorcycle.create(make: "Honda", model: "CBR")

# Each class has different encoded IDs for the same numeric ID
car.encoded_id
# => "car_p5w9-z27j"

motorcycle_id = motorcycle.id
Car.encode_encoded_id(motorcycle_id)
# => "car_x3k8-m9yz"  # Different encoding than motorcycle's

Motorcycle.encode_encoded_id(motorcycle_id)
# => "motorcycle_a7b2-q4wx"  # Different from Car's encoding

# Cross-class lookups won't work
Vehicle.find_by_encoded_id(car.encoded_id)
# => Won't find the car (different salt used for decoding)
```

#### Example 2: Shared Salt for Compatibility

To make encoded IDs work across the STI hierarchy, share the salt:

```ruby
class Vehicle < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam

  def name_for_encoded_id_slug
    "#{make}-#{model}".parameterize
  end
end

class Car < Vehicle
  def self.encoded_id_salt
    # Use parent's salt for compatibility
    EncodedId::Rails::Salt.new(Vehicle, EncodedId::Rails.configuration.salt).generate!
  end
end

class Motorcycle < Vehicle
  def self.encoded_id_salt
    # Use parent's salt for compatibility
    EncodedId::Rails::Salt.new(Vehicle, EncodedId::Rails.configuration.salt).generate!
  end
end

# Now encoded IDs are compatible across the hierarchy
car = Car.create(make: "Toyota", model: "Camry")
motorcycle = Motorcycle.create(make: "Honda", model: "CBR")

# Parent can find children by their encoded IDs
Vehicle.find_by_encoded_id(car.encoded_id)
# => #<Car id: 1, make: "Toyota", model: "Camry">

Vehicle.find_by_encoded_id(motorcycle.encoded_id)
# => #<Motorcycle id: 2, make: "Honda", model: "CBR">

# Children can decode parent's encoded IDs
vehicle = Vehicle.create(make: "Generic", model: "Vehicle")
Car.decode_encoded_id(vehicle.encoded_id)
# => [3]  # Successfully decodes

# Query across hierarchy works
vehicle_ids = [car.encoded_id, motorcycle.encoded_id]
Vehicle.where_encoded_id(vehicle_ids)
# => [#<Car id: 1>, #<Motorcycle id: 2>]
```

#### Example 3: API Endpoint with STI

Here's a practical example using STI with an API:

```ruby
# Models
class Animal < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecordFinders
end

class Dog < Animal
  def self.encoded_id_salt
    EncodedId::Rails::Salt.new(Animal, EncodedId::Rails.configuration.salt).generate!
  end
end

class Cat < Animal
  def self.encoded_id_salt
    EncodedId::Rails::Salt.new(Animal, EncodedId::Rails.configuration.salt).generate!
  end
end

# Controller
class AnimalsController < ApplicationController
  def show
    # Accept encoded IDs for any animal type
    @animal = Animal.find(params[:id])  # Works for Dog, Cat, or Animal

    render json: {
      id: @animal.encoded_id,
      type: @animal.type,
      name: @animal.name
    }
  end

  def bulk_show
    # Accept multiple encoded IDs
    animal_ids = params[:ids]  # Array of encoded IDs
    @animals = Animal.where_encoded_id(animal_ids)

    render json: @animals.map { |animal|
      {
        id: animal.encoded_id,
        type: animal.type,
        name: animal.name
      }
    }
  end
end

# Usage
dog = Dog.create(name: "Buddy")
cat = Cat.create(name: "Whiskers")

# GET /animals/dog_p5w9-z27j
# => { id: "dog_p5w9-z27j", type: "Dog", name: "Buddy" }

# GET /animals/cat_a2k8-3xqz
# => { id: "cat_a2k8-3xqz", type: "Cat", name: "Whiskers" }

# POST /animals/bulk_show?ids[]=dog_p5w9-z27j&ids[]=cat_a2k8-3xqz
# => [
#      { id: "dog_p5w9-z27j", type: "Dog", name: "Buddy" },
#      { id: "cat_a2k8-3xqz", type: "Cat", name: "Whiskers" }
#    ]
```

#### When to Share Salts in STI

**Share salts when:**
- You need a unified API that accepts any type in the hierarchy
- Parent class needs to find children by their encoded IDs
- You're building flexible polymorphic endpoints
- You want to query multiple types at once

**Keep separate salts when:**
- You want strict type checking (additional safety)
- Different types should never cross-reference
- You want to prevent confusion between similar IDs of different types

## Advanced Topics

### Performance Considerations

For Rails applications with frequent encoded ID lookups:

1. **Use the Persists module**: When you frequently look up records by encoded ID, including `EncodedId::Rails::Persists` and adding the necessary database columns can significantly improve performance by avoiding the need to decode IDs.

2. **Be mindful of slugs**: Generating slugs can be expensive if the slug method performs complex operations. Keep your `name_for_encoded_id_slug` implementation efficient.

3. **Cache encoded IDs**: For records that rarely change, consider caching the encoded ID in a cache store like Redis or Memcached.

For general encoder performance (Sqids vs HashIds), see [EncodedId Advanced Topics](../encoded_id/index.html#performance-considerations).

### Security Considerations

It's important to understand the security implications of using encoded IDs.

#### Not for Sensitive Data

**Encoded IDs are not secure**. They are meant to be used for obfuscation, not encryption. It may be possible to reverse them via brute-force, especially for simple or sequential IDs.

Don't use encoded IDs as the sole protection for sensitive resources. Always implement proper authorization checks.

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find_by_encoded_id!(params[:id])

    # Always check authorization!
    authorize! :read, @post  # Use your authorization library
  end
end
```

Read more about the security implications: [Hashids expose salt value](https://www.sjoerdlangkemper.nl/2023/11/25/hashids-expose-salt-value/)

### Salts

**Changing the salt**: If you change your salt, all previously encoded IDs will no longer decode correctly. Have a migration plan if you need to change the salt.

**Per-model salts**: You can configure different salts for different models by overriding the `encoded_id_salt` class method. See the [Configuration](#salt-configuration) documentation for details.
