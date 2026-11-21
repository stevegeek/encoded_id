# Annotated and slugged IDs

An instance has three forms of its ID:

```ruby
user.encoded_id_hash      # => "dchf-51kr"                  the hash only
user.encoded_id           # => "user_dchf-51kr"             annotation + "_" + hash
user.slugged_encoded_id   # => "jane-doe--user_dchf-51kr"   slug + "--" + encoded_id
```

All three return `nil` for a record without an ID. Decoding and every finder accept all three forms.

## Annotation

The annotation tells people what kind of record an ID belongs to. It is the result of the method named by
`config.annotation_method_name` (default `annotation_for_encoded_id`), passed through `parameterize`. The default
method returns the class name underscored, so `LineItem` gives `line_item_...` and `Admin::Thing` gives
`admin-thing_...`.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model

  def annotation_for_encoded_id = "usr"   # => "usr_dchf-51kr"
end
```

To leave out the annotation everywhere, set `config.annotation_method_name = nil`; `encoded_id` then returns the
hash. The annotation method name and `annotated_id_separator` are global settings; `encoded_id_config` does not
take them. Decoding uses the text after the last `annotated_id_separator` and never checks the annotation.

## Slug

```ruby
class Article < ApplicationRecord
  include EncodedId::Rails::Model

  def name_for_encoded_id_slug = title
end

article.slugged_encoded_id   # => "my-first-post--article_dchf-51kr"
```

The slug is the result of the method named by `config.slug_value_method_name` (default
`name_for_encoded_id_slug`), passed through `parameterize`. The default method raises `StandardError`; define it in
each model that uses slugs, or in `ApplicationRecord`. A blank slug raises `StandardError`
("The model does not return a valid ID and/or slug").

The slug is not checked on lookup, so URLs keep working after the title changes.

## Separators

`annotated_id_separator` (default `"_"`) and `slugged_id_separator` (default `"--"`) must not use alphabet
characters, must not be blank and must differ from `group_separator`; `configure` raises `ArgumentError` otherwise.
They are CGI-escaped in the generated ID. Changing them after IDs are issued breaks those IDs.

## to_param

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::PathParam          # to_param => encoded_id
end

class Article < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam   # to_param => slugged_encoded_id
end
```

`to_param` raises `StandardError` for an unsaved record. `config.model_to_param_returns_encoded_id = true` includes
`PathParam` in every model that includes `Model`; it must be set before the models load.

## Memoization

`encoded_id`, `encoded_id_hash` and `slugged_encoded_id` are memoized per record. The memo is cleared on `reload`
and on `dup`, and when the record's ID changes. It is not cleared when the slug's source attribute changes, so after
renaming a record call `clear_encoded_id_cache!` (or `reload`) before reading `slugged_encoded_id` again.
