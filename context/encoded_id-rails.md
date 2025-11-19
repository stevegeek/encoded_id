# EncodedId::Rails - Rails Integration Technical Documentation

## Overview

`encoded_id-rails` provides seamless Rails integration for the `encoded_id` gem, enabling ActiveRecord models to use obfuscated IDs in URLs while maintaining standard Rails conventions. It offers multiple integration strategies from basic encoding to full ActiveRecord finder method overrides.

## Key Features

- **ActiveRecord Integration**: Works seamlessly with Rails models
- **URL-Friendly IDs**: Automatic `to_param` overrides for encoded IDs in routes
- **Slugged IDs**: Human-readable slugs combined with encoded IDs (e.g., `john-doe--user_p5w9-z27j`)
- **Annotated IDs**: Model type prefixes for clarity (e.g., `user_p5w9-z27j`)
- **Finder Methods**: Find records using encoded IDs with familiar ActiveRecord syntax
- **Database Persistence**: Optional storage of encoded IDs for performance with automatic validations
- **Per-Model Configuration**: Different encoding strategies per model with inheritance support
- **ActiveRecord Finder Overrides**: Seamless integration with `find`, `find_by_id`, etc.
- **Record Duplication Safety**: Automatic encoded ID cache clearing on `dup`

## Quick Module Reference

| Module | Purpose | Key Method |
|--------|---------|------------|
| `EncodedId::Rails::Model` | Core functionality | `#encoded_id` |
| `EncodedId::Rails::PathParam` | URLs use encoded IDs | `#to_param` |
| `EncodedId::Rails::SluggedPathParam` | URLs use slugged IDs | `#to_param` |
| `EncodedId::Rails::ActiveRecordFinders` | Transparent finder overrides | `find()` |
| `EncodedId::Rails::Persists` | Database persistence with validations | `set_normalized_encoded_id!` |

## Installation & Setup

```bash
# Add to Gemfile
gem 'encoded_id-rails'

# Install
bundle install

# Generate configuration (prompts for encoder choice: sqids or hashids)
rails generate encoded_id:rails:install

# Or specify encoder directly
rails generate encoded_id:rails:install --encoder=sqids
# or
rails generate encoded_id:rails:install --encoder=hashids
```

The generator creates `config/initializers/encoded_id.rb` with encoder-specific configuration:
- **Sqids**: No salt required, ready to use
- **Hashids**: Requires salt configuration (generator includes commented template)

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
Override to customize the annotation prefix (defaults to `model_name.underscore`).

```ruby
def annotation_for_encoded_id
  "usr"  # => "usr_p5w9-z27j"
end
```

##### clear_encoded_id_cache!
Manually clear memoized encoded ID values. Called automatically on `reload` and `dup`.

```ruby
user.clear_encoded_id_cache!
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

```ruby
User.find_by_encoded_id!("user_p5w9-z27j")
# Raises ActiveRecord::RecordNotFound if not found
```

##### find_all_by_encoded_id(encoded_id)
Find multiple records when encoded ID contains multiple IDs (returns nil if none found).

```ruby
# If encoded ID represents [78, 45]
User.find_all_by_encoded_id("z2j7-0dmw")
# => [#<User id: 78>, #<User id: 45>]
```

##### find_all_by_encoded_id!(encoded_id)
Same as above but raises `ActiveRecord::RecordNotFound` if:
- No records found
- Number of records doesn't match number of decoded IDs

```ruby
User.find_all_by_encoded_id!("z2j7-0dmw")
# Raises if records not found or count mismatch
```

##### where_encoded_id(*encoded_ids)
Returns ActiveRecord relation for chaining. Can take multiple IDs.

```ruby
User.where_encoded_id("user_p5w9-z27j").where(active: true)
User.where_encoded_id("id1", "id2", "id3")
```

##### encode_encoded_id(id, **options)
Encode a specific ID using model's configuration (optionally override options).

```ruby
User.encode_encoded_id(123) # => "p5w9-z27j"
User.encode_encoded_id(123, id_length: 12) # Override length
```

##### decode_encoded_id(encoded_id)
Decode an encoded ID using model's configuration.

```ruby
User.decode_encoded_id("user_p5w9-z27j") # => [123]
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

**IMPORTANT**: Only use with integer primary keys. Do NOT use with string-based primary keys (UUIDs).

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

### EncodedId::Rails::Persists

Stores encoded IDs in database for performance with automatic validations.

```bash
# Generate migration
rails generate encoded_id:rails:add_columns User

# Creates migration adding:
# - normalized_encoded_id (string) - for lookups without separators/annotations
# - prefixed_encoded_id (string) - with annotation prefix
```

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end
```

**Automatic Validations**:
- Uniqueness validation on `normalized_encoded_id`
- Uniqueness validation on `prefixed_encoded_id`
- Read-only enforcement after creation (prevents manual updates)

**Callbacks**:
- `after_create`: Automatically sets encoded IDs
- `before_save`: Updates encoded IDs if ID changed
- `after_commit`: Validates persisted values match computed values

**Instance Methods**:

##### set_normalized_encoded_id!
Manually update persisted encoded IDs (uses `update_columns` to bypass callbacks).

```ruby
user.set_normalized_encoded_id!
```

##### update_normalized_encoded_id!
Update persisted encoded IDs in-memory (will be saved with record).

```ruby
user.update_normalized_encoded_id!
user.save
```

**Database Lookups**:

```ruby
# Fast lookups via direct DB query
User.where(normalized_encoded_id: "p5w9z27j").first
User.where(prefixed_encoded_id: "user_p5w9-z27j").first

# IMPORTANT: Add indexes for performance
# See migration section below
```

**Record Duplication**:
When using `dup`, persisted encoded ID columns are automatically set to `nil` for the new record:

```ruby
new_user = existing_user.dup
new_user.normalized_encoded_id # => nil (will be set on save)
new_user.prefixed_encoded_id   # => nil
```

## Configuration

### Global Configuration

```ruby
# config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  # Required for Hashids encoder
  config.salt = "your-secret-salt"  # Not required for Sqids

  # Basic Options
  config.id_length = 8                    # Minimum length
  config.character_group_size = 4         # Split every X chars
  config.group_separator = "-"            # Split character
  config.alphabet = EncodedId::Alphabet.modified_crockford

  # Annotation/Prefix Options
  config.annotation_method_name = :annotation_for_encoded_id
  config.annotated_id_separator = "_"

  # Slug Options
  config.slug_value_method_name = :name_for_encoded_id_slug
  config.slugged_id_separator = "--"

  # Encoder Selection
  config.encoder = :sqids                 # Default: :sqids (or :hashids for backwards compatibility)
  config.downcase_on_decode = false       # Default: false (set to true for pre-v1 compatibility)

  # Blocklist
  config.blocklist = nil                  # EncodedId::Blocklist.minimal or custom

  # Auto-include PathParam (makes all models use encoded IDs in URLs)
  config.model_to_param_returns_encoded_id = false
end
```

**Note**: As of v1.0.0:
- Default encoder is `:sqids` (no salt required)
- `downcase_on_decode` defaults to `false` (case-sensitive)
- For backwards compatibility with pre-v1: set `encoder: :hashids` and `downcase_on_decode: true`

### Encoder-Specific Notes

**Sqids (default)**:
- No salt required
- Automatically avoids blocklisted words via iteration
- Faster decoding

**Hashids**:
- Requires salt (minimum 4 characters)
- Raises `EncodedId::BlocklistError` if blocklisted word appears
- Faster encoding, especially with blocklists

### Per-Model Configuration

#### Using `encoded_id_config` (Recommended)

The cleanest way to configure encoding options per model:

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model

  # Configure encoder settings for this model
  encoded_id_config encoder: :hashids, id_length: 12
end
```

**Supports all configuration options**:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model

  encoded_id_config(
    encoder: :sqids,
    id_length: 12,
    character_group_size: 3,
    alphabet: EncodedId::Alphabet.new("0123456789ABCDEF"),
    blocklist: EncodedId::Blocklist.minimal,
    downcase_on_decode: true
  )
end
```

**Available Options**:
- `encoder` - `:sqids` or `:hashids`
- `id_length` - Minimum encoded ID length
- `character_group_size` - Character grouping (nil for no grouping)
- `alphabet` - Custom alphabet
- `blocklist` - Blocklist instance or array
- `downcase_on_decode` - Case-insensitive decoding
- `annotation_method_name` - Method to call for annotation
- `annotated_id_separator` - Separator for annotated IDs
- `slug_value_method_name` - Method to call for slug
- `slugged_id_separator` - Separator for slugged IDs

**Note**: For advanced blocklist control (modes like `:length_threshold`, `:always`, `:raise_if_likely`), use the base `EncodedId::ReversibleId` directly or configure via custom coder.

**Configuration Inheritance**: Child classes inherit their parent's configuration:

```ruby
class BaseModel < ApplicationRecord
  self.abstract_class = true
  include EncodedId::Rails::Model

  # All child models inherit these settings
  encoded_id_config encoder: :hashids, id_length: 10
end

class User < BaseModel
  # Inherits encoder: :hashids, id_length: 10
end

class Product < BaseModel
  # Override parent settings
  encoded_id_config encoder: :sqids
  # Now uses encoder: :sqids but still id_length: 10
end
```

#### Custom Salt Per Model

Override salt per model (Hashids only):

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model

  def self.encoded_id_salt
    "user-specific-salt"
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

### With Slugged IDs

```ruby
# routes.rb
resources :articles

# ArticlesController
class ArticlesController < ApplicationController
  def show
    # Handles slugged IDs automatically
    @article = Article.find_by_encoded_id!(params[:id])
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

  # Configure encoding options for this model
  encoded_id_config(
    blocklist: EncodedId::Blocklist.minimal,
    id_length: 10
  )

  def name_for_encoded_id_slug
    name.parameterize
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

When adding `Persists` module to existing models:

```ruby
# 1. Generate and run migration
rails generate encoded_id:rails:add_columns User
# Edit migration to add indexes (see below)
rails db:migrate

# 2. Backfill existing records
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

**Enhanced Migration with Indexes** (recommended):

```ruby
class AddEncodedIdColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :normalized_encoded_id, :string
    add_column :users, :prefixed_encoded_id, :string

    # Add indexes for performance (critical for lookups)
    add_index :users, :normalized_encoded_id, unique: true
    add_index :users, :prefixed_encoded_id, unique: true
  end
end
```

### Accessing Configuration

```ruby
# Access global configuration
EncodedId::Rails.configuration.salt
EncodedId::Rails.configuration.encoder  # => :sqids
EncodedId::Rails.configuration.id_length  # => 8

# Access model-specific configuration
User.encoded_id_salt
User.encoded_id_coder.encoder
User.encoded_id_options  # => Hash of configured options
```

## Performance Considerations

1. **Persistence**: Use `EncodedId::Rails::Persists` for high-traffic lookups
2. **Indexes**: ALWAYS add database indexes on `normalized_encoded_id` and `prefixed_encoded_id`
3. **Caching**: Encoded IDs are deterministic and memoized per record - cache them if needed
4. **Blocklists**: Large blocklists impact encoding performance, especially with Sqids (iterates to avoid words)
5. **Blocklist Modes**:
   - Sqids: Iteratively regenerates to avoid blocklisted words (may impact performance)
   - Hashids: Raises exception if blocklisted word detected (requires retry logic)
   - For advanced control, use base `EncodedId` configuration directly

## Best Practices

1. **Consistent Configuration**: Don't change salt/encoder after going to production
2. **Model Naming**: Use clear annotation prefixes to identify model types
3. **Error Handling**: Always use `find_by_encoded_id!` in controllers for proper 404s
4. **URL Design**: Choose between encoded IDs vs slugged IDs based on UX needs
5. **Testing**: Test with both regular IDs and encoded IDs in your specs
6. **Indexes**: Always add database indexes when using `Persists` module
7. **Validations**: Rely on automatic validations from `Persists` - don't manually update columns
8. **Record Duplication**: `dup` automatically clears encoded IDs - persisted IDs set to nil for new records

## Debugging

```ruby
# Check configuration
user = User.first
user.class.encoded_id_salt
user.class.encoded_id_coder.encoder
user.class.encoded_id_options

# Test encoding/decoding
encoded = User.encode_encoded_id(123)
decoded = User.decode_encoded_id(encoded)

# Inspect persisted values (if using Persists)
user.normalized_encoded_id
user.prefixed_encoded_id

# Clear and regenerate encoded IDs
user.clear_encoded_id_cache!
user.encoded_id  # Regenerates
```

## Security Considerations

- Encoded IDs are obfuscated, NOT encrypted
- Don't rely on them for authentication or authorization
- They help prevent enumeration attacks but aren't cryptographically secure
- Always validate decoded IDs before database operations
- Use `find_by_encoded_id!` to ensure proper error handling

## Example Use Cases

1. **Public-Facing IDs**: Hide sequential database IDs from users
2. **SEO-Friendly URLs**: Combine slugs with encoded IDs (`cool-gadget--product_k6j8`)
3. **API Design**: Provide opaque identifiers that don't leak information
4. **Multi-Tenant Apps**: Use different salts per tenant for isolation
5. **Legacy Migration**: Gradually move from numeric to encoded IDs
6. **Referral Codes**: Encode user IDs into shareable links
7. **Soft Launches**: Hide actual user/item counts from competitors
