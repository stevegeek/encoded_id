# EncodedId::Rails (`encoded_id-rails`)

[EncodedId](https://github.com/stevegeek/encoded_id) for Rails and `ActiveRecord` models.

EncodedID lets you turn numeric or hex IDs into reversible and human friendly obfuscated strings.

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
  
  def name_for_encoded_id_slug
    full_name.parameterize
  end
end

user = User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
user.encoded_id  # => "p5w9-z27j"
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
```

# Features

- encoded IDs are reversible (see [`encoded_id`](https://github.com/stevegeek/encoded_id))
- supports slugged IDs (eg `my-cool-product-name--p5w9-z27j`) that are URL friendly (assuming your alphabet is too)
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

Include `EncodedId::WithEncodedId` in your model and optionally specify a encoded id salt (or not if using a global one):

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
  
  # and optionally the model's salt
  def encoded_id_salt
    "my-user-model-salt"
  end
  
  # ...
end
```

## Documentation

### `.find_by_encoded_id`

Like `.find` but accepts an encoded ID string instead of an ID. Will return `nil` if no record is found.

```ruby
user = User.find_by_encoded_id("p5w9-z27j")  # => #<User id: 78>
user.encoded_id  # => "p5w9-z27j"
```

### `.find_by_encoded_id!`

Like `.find!` but accepts an encoded ID string instead of an ID. Raises `ActiveRecord::RecordNotFound` if no record is found.

```ruby
user = User.find_by_encoded_id!("p5w9-z27j")  # => #<User id: 78>

# raises ActiveRecord::RecordNotFound
user = User.find_by_encoded_id!("encoded-id-that-is-not-found")  # => ActiveRecord::RecordNotFound
```

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
  include EncodedId::WithEncodedId
  
  def encoded_id_salt
    "my-user-model-salt"
  end
end
User.encoded_id_salt  # => "my-user-model-salt"
```

### `#encoded_id`

Use the `encoded_id` instance method to get the encoded ID for the record:

```ruby
user = User.create(name: "Bob Smith")
user.encoded_id  # => "p5w9-z27j"
```


### `#slugged_encoded_id`

Use the `slugged_encoded_id` instance method to get the slugged version of the encoded ID for the record. 
Calls `#name_for_encoded_id_slug` on the record to get the slug part of the encoded ID:

```ruby
user = User.create(name: "Bob Smith")
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
```

### `#name_for_encoded_id_slug`

Use `#name_for_encoded_id_slug` to specify what will be used to create the slug part of the encoded ID. 
By default it calls `#name` on the instance, or if the instance does not respond to 
`name` (or the value returned is blank) then uses the Model name.

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
  
  # If User has an attribute `name`, that will be used for the slug, 
  # otherwise `user` will be used as determined by the class name.
end

user = User.create(name: "Bob Smith")
user.slugged_encoded_id  # => "bob-smith--p5w9-z27j"
user2 = User.create(name: "")
user2.slugged_encoded_id  # => "user--i74r-bn28"
```

You can optionally override this method to define your own slug:

```ruby
class User < ApplicationRecord
  include EncodedId::WithEncodedId
  
  def name_for_encoded_id_slug
    superhero_name
  end
end

user = User.create(superhero_name: "Super Dev")
user.slugged_encoded_id  # => "super-dev--37nw-8nh7"
```

## To use on all models

Simply add the mixin to your `ApplicationRecord`:

```ruby 
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include EncodedId::WithEncodedId
  
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
