# EncodedId::Rails (`encoded_id-rails`)

[EncodedId](https://github.com/stevegeek/encoded_id) for Rails and `ActiveRecord` models.

EncodedID lets you turn numeric or hex IDs into reversible and human friendly obfuscated strings.

```ruby
class User < ApplicationRecord
  include EncodedId::Model

  # An optional slug for the encoded ID string. This is prepended to the encoded ID string, and is solely 
  # to make the ID human friendly, or useful in URLs. It is not required for finding records by encoded ID.
  def name_for_encoded_id_slug
    full_name
  end
  
  # An optional prefix on the encoded ID string to help identify the model it belongs to.
  # Default is to use model's parameterized name, but can be overridden, or disabled.
  # Note it is not required for finding records by encoded ID.
  def annotation_for_encoded_id
    "usr"
  end
end

# You can find by the encoded ID
user = User.find_by_encoded_id("p5w9-z27j") # => #<User id: 78>
user.encoded_id                             # => "usr_p5w9-z27j"
user.slugged_encoded_id                     # => "bob-smith--usr_p5w9-z27j"

# You can find by a slugged & annotated encoded ID
user == User.find_by_encoded_id("bob-smith--usr_p5w9-z27j") # => true

# Encoded IDs can encode multiple IDs at the same time
users = User.find_all_by_encoded_id("7aq60zqw") # => [#<User id: 78>, #<User id: 45>]
```

# Features

- encoded IDs are reversible (see [`encoded_id`](https://github.com/stevegeek/encoded_id))
- supports slugged IDs (eg `my-cool-product-name--p5w9-z27j`) that are URL friendly (assuming your alphabet is too)
- supports annotated IDs to help identify the model the encoded ID belongs to (eg for a `User` the encoded ID might be `user_p5w9-z27j`) 
- encoded string can be split into groups of letters to improve human-readability (eg `abcd-efgh`)
- supports multiple IDs encoded in one encoded string (eg imagine the encoded ID `7aq60zqw` might decode to two IDs `[78, 45]`)
- supports custom alphabets for the encoded string (at least 16 characters needed)
  - by default uses a variation of the Crockford reduced character set (https://www.crockford.com/base32.html) 
  - easily confused characters (eg i and j, 0 and O, 1 and I etc) are mapped to counterpart characters, to 
    help avoid common readability mistakes when reading/sharing
  - build in profanity limitation

The gem provides:

- methods to mixin to ActiveRecord models which will allow you to encode and decode IDs, and find
  or query by encoded IDs
- sensible defaults to allow you to get started out of the box

### Coming in future (?)

- support for UUIDs for IDs (which will be encoded as an array of integers)

# Why this gem?

With this gem you can easily obfuscate your IDs in your URLs, and still be able to find records by using
the encoded IDs. The encoded IDs are meant to be somewhat human friendly, to make communication easier
when sharing encoded IDs with other people. 

* Hashids are reversible, no need to persist the generated Id
* we don't override any AR methods. `encoded_id`s are intentionally not interchangeable with normal record `id`s 
  (ie you can't use `.find` to find by encoded ID or record ID, you must be explicit)
* we support slugged IDs (eg `my-amazing-product--p5w9-z27j`)
* we support multiple model IDs encoded in one `EncodedId` (eg `7aq6-0zqw` might decode to `[78, 45]`)
* the gem is configurable
* encoded IDs can be stable across environments, or not (you can set the salt to different values per environment)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add encoded_id-rails

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install encoded_id-rails

Then run the generator to add the initializer:

    rails g encoded_id:rails:install

## Usage

### Configuration

The install generator will create an initializer file [`config/initializers/encoded_id.rb`](https://github.com/stevegeek/encoded_id-rails/blob/main/lib/generators/encoded_id/rails/templates/encoded_id.rb). It is documented
and should be self-explanatory.

You can configure:

- a global salt needed to generate the encoded IDs (if you dont use a global salt, you can set a salt per model)
- the size of the character groups in the encoded string (default is 4) 
- the separator between the character groups (default is '-')
- the alphabet used to generate the encoded string (default is a variation of the Crockford reduced character set)
- the minimum length of the encoded ID string (default is 8 characters)

### ActiveRecord model setup

Include `EncodedId::Model` in your model and optionally specify a encoded id salt (or not if using a global one):

```ruby
class User < ApplicationRecord
  include EncodedId::Model

  # and optionally the model's salt
  def encoded_id_salt
    "my-user-model-salt"
  end

  # ...
end
```

### Optional mixins

You can optionally include one of the following mixins to add default overrides to `#to_param`.

- `EncodedId::PathParam`
- `EncodedId::SluggedPathParam`

This is so that an instance of the model can be used in path helpers and 
return the encoded ID string instead of the record ID by default.

```ruby
class User < ApplicationRecord
  include EncodedId::Model
  include EncodedId::SluggedPathParam

  def name_for_encoded_id_slug
    full_name
  end
end

user = User.create(full_name: "Bob Smith")
Rails.application.routes.url_helpers.user_path(user) # => "/users/bob-smith--p5w9-z27j"
```

## Documentation

### `.find_by_encoded_id`

Like `.find` but accepts an encoded ID string instead of an ID. Will return `nil` if no record is found.

```ruby
user = User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
user.encoded_id  # => "p5w9-z27j"
```

Note when an encoded ID string contains multiple IDs, this method will return the record for the first ID.

### `.find_by_encoded_id!`

Like `.find!` but accepts an encoded ID string instead of an ID. Raises `ActiveRecord::RecordNotFound` if no record is found.

```ruby
user = User.find_by_encoded_id!("p5w9-z27j")  # => #<User id: 78>

# raises ActiveRecord::RecordNotFound
user = User.find_by_encoded_id!("encoded-id-that-is-not-found")  # => ActiveRecord::RecordNotFound
```

Note when an encoded ID string contains multiple IDs, this method will return the record for the first ID.

### `.find_all_by_encoded_id`

Like `.find_by_encoded_id` but when an encoded ID string contains multiple IDs, 
this method will return an array of records.

### `.find_all_by_encoded_id!`

Like `.find_by_encoded_id!` but when an encoded ID string contains multiple IDs, 
this method will return an array of records.

### `.where_encoded_id`

A helper for creating relations. Decodes the encoded ID string before passing it to `.where`.

```ruby
encoded_id = User.encode_encoded_id([user1.id, user2.id])  # => "p5w9-z27j"
User.where(active: true)
  .where_encoded_id(encoded_id)
  .map(&:name) # => ["Bob Smith", "Jane Doe"]
```

### `.encode_encoded_id`

Encodes an ID or array of IDs into an encoded ID string.

```ruby
User.encode_encoded_id(78)  # => "p5w9-z27j"
User.encode_encoded_id([78, 45])  # => "7aq6-0zqw"
```

### `.decode_encoded_id`

Decodes an encoded ID string into an array of IDs.

```ruby
User.decode_encoded_id("p5w9-z27j")  # => [78]
User.decode_encoded_id("7aq6-0zqw")  # => [78, 45]
```

### `.encoded_id_salt`

Returns the salt used to generate the encoded ID string. If not defined, the global salt is used
with `EncodedId::Rails::Salt` to generate a model specific one.

```ruby
User.encoded_id_salt  # => "User/the-salt-from-the-initializer"
```

Otherwise override this method to return a salt specific to the model.

```ruby
class User < ApplicationRecord
  include EncodedId::Model

  def encoded_id_salt
    "my-user-model-salt"
  end
end

User.encoded_id_salt  # => "my-user-model-salt"
```

### `#encoded_id_hash`

Returns only the encoded 'hashId' part of the encoded ID for the record:

```ruby
user = User.create(name: "Bob Smith")
user.encoded_id  # => "p5w9-z27j"
```


### `#encoded_id`

Returns the encoded ID for the record, with an annotation (if it is enabled):

```ruby
user = User.create(name: "Bob Smith")
user.encoded_id  # => "user_p5w9-z27j"
```

By default, the annotation comes from the underscored model name. However, you can change this by either:

- overriding `#annotation_for_encoded_id` on the model
- overriding `#annotation_for_encoded_id` on all models via your `ApplicationRecord`
- change the method called to get the annotation via setting the `annotation_method_name` config options in your initializer
- disable the annotation via setting the `annotation_method_name` config options in your initializer to `nil`


Examples: 

```ruby
EncodedId::Rails.configuration.annotation_method_name = :name
user.encoded_id  # => "bob_smith_p5w9-z27j"
```

```ruby
EncodedId::Rails.configuration.annotation_method_name = nil
user.encoded_id  # => "p5w9-z27j"
```

```ruby
class User < ApplicationRecord
  include EncodedId::Model
  
  def annotation_for_encoded_id
    "foo"
  end
end

user = User.create(name: "Bob Smith")
user.encoded_id  # => "foo_p5w9-z27j"
```

Note that you can also configure the annotation separator via the `annotated_id_separator` config option in your initializer,
but it must be set to a string that only contains character that are not part of the alphabet used to encode the ID.

```ruby
EncodedId::Rails.configuration.annotated_id_separator = "^^"
user.encoded_id  # => "foo^^p5w9-z27j"
```

### `#slugged_encoded_id`

Use the `slugged_encoded_id` instance method to get the slugged version of the encoded ID for the record. 

```ruby
user = User.create(name: "Bob Smith")
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
```

Calls `#name_for_encoded_id_slug` on the record to get the slug part of the encoded ID.
By default, `#name_for_encoded_id_slug` raises, and must be overridden, or configured via the `slug_value_method_name` config option in your initializer:

```ruby
class User < ApplicationRecord
  include EncodedId::Model

  # Assuming user has a name attribute
  def name_for_encoded_id_slug
    name
  end
end

user = User.create(name: "Bob Smith")
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
```

You can optionally override this method to define your own slug:

```ruby
class User < ApplicationRecord
  include EncodedId::Model

  def name_for_encoded_id_slug
    superhero_name
  end
end

user = User.create(superhero_name: "Super Dev")
user.slugged_encoded_id  # => "super-dev--37nw-8nh7"
```

Configure the method called by setting the `slug_value_method_name` config option in your initializer:

```ruby
EncodedId::Rails.configuration.slug_value_method_name = :name
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
```

Note that you can also configure the slug separator via the `slugged_id_separator` config option in your initializer,
but it must be set to a string that only contains character that are not part of the alphabet used to encode the ID.

```ruby
EncodedId::Rails.configuration.annotated_id_separator = "***"
user.encoded_id  # => "bob-smith***p5w9-z27j"
```

## To use on all models

Simply add the mixin to your `ApplicationRecord`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include EncodedId::Model

  ...
end
```

However, I recommend you only use it on the models that need it.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Type check

First install dependencies:

```bash
rbs collection install
```

Then run:

```bash
steep check
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevegeek/encoded_id-rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
