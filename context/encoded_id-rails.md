# EncodedId::Rails - Rails Integration Technical Documentation

## Overview

`encoded_id-rails` provides seamless Rails integration for the `encoded_id` gem, enabling ActiveRecord models to use obfuscated IDs in URLs while maintaining standard Rails conventions. It offers multiple integration strategies from basic encoding to full ActiveRecord finder method overrides.

## Key Features

- **ActiveRecord Integration**: Works seamlessly with Rails models
- **URL-Friendly IDs**: Automatic `to_param` overrides for encoded IDs in routes
- **Slugged IDs**: Human-readable slugs combined with encoded IDs (e.g., `john-doe--user_p5w9-z27j`)
- **Annotated IDs**: Model type prefixes for clarity (e.g., `user_p5w9-z27j`)
- **Finder Methods**: Find records using encoded IDs with familiar ActiveRecord syntax
- **Database Persistence**: Optional storage of encoded IDs for performance
- **Per-Model Configuration**: Different encoding strategies per model
- **ActiveRecord Finder Overrides**: Seamless integration with `find`, `find_by_id`, etc.

## Installation & Setup

```bash
# Add to Gemfile
gem 'encoded_id-rails'

# Install
bundle install

# Generate configuration
rails generate encoded_id:rails:install
```

This creates `config/initializers/encoded_id.rb` with configuration options.

## Core Modules

### EncodedId::Rails::Model

The base module that provides core functionality.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
end
```

#### Instance Methods

##### encoded_id
Returns the encoded ID with optional annotation prefix.

```ruby
user = User.find(123)
user.encoded_id # => "user_p5w9-z27j"
```

##### slugged_encoded_id
Returns encoded ID with human-readable slug.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def name_for_encoded_id_slug
    full_name.parameterize
  end
end

user.slugged_encoded_id # => "john-doe--user_p5w9-z27j"
```

##### annotation_for_encoded_id
Override to customize the annotation prefix.

```ruby
def annotation_for_encoded_id
  "usr"  # => "usr_p5w9-z27j"
end
```

#### Class Methods

##### find_by_encoded_id(encoded_id)
Find record by encoded ID (returns nil if not found).

```ruby
User.find_by_encoded_id("user_p5w9-z27j")     # With annotation
User.find_by_encoded_id("p5w9-z27j")          # Just the hash
User.find_by_encoded_id("john-doe--user_p5w9-z27j") # Slugged
```

##### find_by_encoded_id!(encoded_id)
Same as above but raises `ActiveRecord::RecordNotFound` if not found.

##### find_all_by_encoded_id(encoded_id)
Find multiple records when encoded ID contains multiple IDs.

```ruby
# If encoded ID represents [78, 45]
User.find_all_by_encoded_id("z2j7-0dmw")
# => [#<User id: 78>, #<User id: 45>]
```

##### where_encoded_id(encoded_id)
Returns ActiveRecord relation for chaining.

```ruby
User.where_encoded_id("user_p5w9-z27j").where(active: true)
```

##### encode_encoded_id(id)
Encode a specific ID using model's configuration.

```ruby
User.encode_encoded_id(123) # => "p5w9-z27j"
```

### EncodedId::Rails::PathParam

Makes models use encoded IDs in URL helpers.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam
end

user.to_param # => "user_p5w9-z27j"

# In routes
link_to "View", user_path(user) # => "/users/user_p5w9-z27j"
```

### EncodedId::Rails::SluggedPathParam

Uses slugged encoded IDs in URLs.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  
  def name_for_encoded_id_slug
    full_name.parameterize
  end
end

user.to_param # => "john-doe--user_p5w9-z27j"
```

### EncodedId::Rails::ActiveRecordFinders

Overrides standard ActiveRecord finders to handle encoded IDs transparently.

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecordFinders
end

# Now these all work with encoded IDs
Product.find("product_p5w9-z27j")
Product.find_by_id("product_p5w9-z27j")
Product.where(id: "product_p5w9-z27j")

# Still works with regular IDs
Product.find(123)

# In controllers, no changes needed
def show
  @product = Product.find(params[:id]) # Works with both
end
```

**Warning**: Do NOT use with string-based primary keys (UUIDs).

### EncodedId::Rails::Persists

Stores encoded IDs in database for performance.

```bash
# Generate migration
rails generate encoded_id:rails:add_columns User

# Adds columns:
# - normalized_encoded_id (string)
# - prefixed_encoded_id (string)
```

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end

# Fast lookups via direct DB query
User.where(normalized_encoded_id: "p5w9z27j").first

# Add index for performance
add_index :users, :normalized_encoded_id, unique: true
```

## Configuration

### Global Configuration

```ruby
# config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  # Required
  config.salt = "your-secret-salt"
  
  # Optional
  config.id_length = 8                    # Minimum length
  config.character_group_size = 4         # Split every X chars
  config.group_separator = "-"            # Split character
  config.alphabet = EncodedId::Alphabet.modified_crockford
  config.annotation_method_name = :annotation_for_encoded_id
  config.annotated_id_separator = "_"
  config.slug_value_method_name = :name_for_encoded_id_slug
  config.slugged_id_separator = "--"
  config.model_to_param_returns_encoded_id = false
  config.encoder = :hashids               # or :sqids
  config.blocklist = nil
  config.hex_digit_encoding_group_size = 4
end
```

### Per-Model Configuration

Override salt per model:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  def self.encoded_id_salt
    "user-specific-salt"
  end
end
```

### Advanced Model Configuration

Full control via `encoded_id_coder`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  
  def self.encoded_id_coder(options = {})
    super(options.merge(
      encoder: :sqids,
      id_length: 12,
      character_group_size: 3,
      group_separator: ".",
      alphabet: EncodedId::Alphabet.new("0123456789ABCDEF"),
      blocklist: ["BAD", "FAKE"]
    ))
  end
end
```

### Contextual Encoding

Different configurations for different use cases:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  
  # Short ID for QR codes
  def qr_encoded_id
    self.class.encode_encoded_id(id, 
      id_length: 6, 
      character_group_size: nil
    )
  end
  
  # API-friendly (no separators/annotations)
  def api_encoded_id
    self.class.encode_encoded_id(id, 
      character_group_size: nil,
      annotation_method_name: nil
    )
  end
end
```

## Routes & Controllers

### Basic Setup

```ruby
# routes.rb
Rails.application.routes.draw do
  resources :users, param: :encoded_id
end

# UsersController
class UsersController < ApplicationController
  def show
    @user = User.find_by_encoded_id!(params[:encoded_id])
  end
end
```

### With ActiveRecordFinders

```ruby
# routes.rb - standard :id param
resources :products

# ProductsController
class ProductsController < ApplicationController
  def show
    # Works with both regular and encoded IDs
    @product = Product.find(params[:id])
  end
end
```

## Common Patterns

### Complete Integration Example

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam
  include EncodedId::Rails::Persists
  include EncodedId::Rails::ActiveRecordFinders
  
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

# Usage
product = Product.create(name: "Cool Gadget")
product.encoded_id           # => "product_k6jR8Myo23"
product.slugged_encoded_id   # => "cool-gadget--product_k6jR8Myo23"

# All these work
Product.find("product_k6jR8Myo23")
Product.find("cool-gadget--product_k6jR8Myo23")
Product.find_by_encoded_id("k6jR8Myo23")
Product.where_encoded_id("product_k6jR8Myo23").active

# URLs automatically use slugged IDs
product_path(product) # => "/products/cool-gadget--product_k6jR8Myo23"
```

### Migration for Existing Data

```ruby
# For persisted encoded IDs
User.find_each(batch_size: 1000) do |user|
  user.set_normalized_encoded_id!
end

# Or via background job
class BackfillEncodedIdsJob < ApplicationJob
  def perform(model_class, start_id, end_id)
    model_class.where(id: start_id..end_id).find_each do |record|
      record.set_normalized_encoded_id!
    end
  end
end
```

## Performance Considerations

1. **Persistence**: Use `EncodedId::Rails::Persists` for high-traffic lookups
2. **Indexes**: Add database indexes on `normalized_encoded_id`
3. **Caching**: Encoded IDs are deterministic - cache them if needed
4. **Blocklists**: Large blocklists impact performance, especially with Sqids

## Best Practices

1. **Consistent Configuration**: Don't change salt/encoder after going to production
2. **Model Naming**: Use clear annotation prefixes to identify model types
3. **Error Handling**: Always use `find_by_encoded_id!` in controllers for proper 404s
4. **URL Design**: Choose between encoded IDs vs slugged IDs based on UX needs
5. **Testing**: Test with both regular IDs and encoded IDs in your specs

## Troubleshooting

### Load Order Issues

```ruby
# In initializer if seeing load errors
require 'encoded_id'
require 'encoded_id/rails'

# Or in ApplicationRecord
require 'encoded_id/rails/model'
require 'encoded_id/rails/path_param'
```

### Debugging

```ruby
# Check configuration
user = User.first
user.class.encoded_id_salt
user.class.encoded_id_coder.encoder

# Test encoding/decoding
encoded = User.encode_encoded_id(123)
decoded = User.decode_encoded_id(encoded)
```

## Security Considerations

- Encoded IDs are obfuscated, NOT encrypted
- Don't rely on them for authentication or authorization
- They help prevent enumeration attacks but aren't cryptographically secure
- Always validate decoded IDs before database operations

## Example Use Cases

1. **Public-Facing IDs**: Hide sequential database IDs from users
2. **SEO-Friendly URLs**: Combine slugs with encoded IDs for best of both worlds
3. **API Design**: Provide opaque identifiers that don't leak information
4. **Multi-Tenant Apps**: Use different salts per tenant for isolation
5. **Legacy Migration**: Gradually move from numeric to encoded IDs