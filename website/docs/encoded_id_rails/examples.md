---
layout: default
title: Examples
parent: EncodedId::Rails
nav_order: 4
---

# Examples
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

2. This page provides various examples of using EncodedId::Rails in different scenarios.

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

## Encoder Configuration

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

See [Configuration](configuration.html#encoder) for encoder options and requirements.

## Per-Model Encoder Configuration

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

  # Configure a custom blocklist for this model
  encoded_id_config blocklist: ["product", "item"]
end
```

## ActiveRecord Finder Integration

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

## Combining Multiple Features

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

## Single Table Inheritance (STI) {#single-table-inheritance-sti}

When using EncodedId with Single Table Inheritance, you need to decide whether child classes should share the same salt as the parent.

By default, each class in an STI hierarchy has its own unique salt, making encoded IDs incompatible across classes. This section shows how to handle both scenarios.

### Example 1: Default Behavior (Separate Salts)

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

### Example 2: Shared Salt for Compatibility

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

### Example 3: API Endpoint with STI

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

### When to Share Salts in STI

**Share salts when:**
- You need a unified API that accepts any type in the hierarchy
- Parent class needs to find children by their encoded IDs
- You're building flexible polymorphic endpoints
- You want to query multiple types at once

**Keep separate salts when:**
- You want strict type checking (additional safety)
- Different types should never cross-reference
- You want to prevent confusion between similar IDs of different types