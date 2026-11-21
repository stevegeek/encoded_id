---
name: encoded-id-rails
description: "Use when adding or changing encoded IDs on ActiveRecord models with the encoded_id-rails gem (EncodedId::Rails): the initializer and EncodedId::Rails.configure, per-model encoded_id_config, find_by_encoded_id and the other finders, encoded IDs in routes and to_param, slugged or annotated IDs, persisted encoded ID columns, and tests that change the configuration. For encoding outside models, use the encoded-id skill."
---

# encoded_id-rails

`encoded_id-rails` gives ActiveRecord models reversible, URL-safe IDs such as `user_dchf-51kr` or
`jane-doe--user_dchf-51kr`, built on the `encoded_id` gem. Encoded IDs obfuscate; they do not authorize. Keep
your access checks.

## Quick reference

```bash
bundle add encoded_id-rails
bin/rails generate encoded_id:rails:install --encoder=sqids   # writes config/initializers/encoded_id.rb
```

```ruby
# config/initializers/encoded_id.rb
EncodedId::Rails.configure do |config|
  config.salt = "a-long-random-salt"   # needed by the model even with Sqids, see below
end

class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::SluggedPathParam   # or PathParam; optional

  def name_for_encoded_id_slug = name
end

user.encoded_id                              # => "user_dchf-51kr"
user.slugged_encoded_id                      # => "jane-doe--user_dchf-51kr"
user.to_param                                # => "jane-doe--user_dchf-51kr"
User.find_by_encoded_id("user_dchf-51kr")    # => user, or nil
User.find_by_encoded_id!(params[:id])        # raises ActiveRecord::RecordNotFound (a 404)
User.where_encoded_id(params[:id]).where(active: true)
User.encode_encoded_id(user.id)              # => "dchf-51kr"
User.decode_encoded_id("jane-doe--user_dchf-51kr")   # => [1]
```

| Module | Adds |
|---|---|
| `EncodedId::Rails::Model` | `encoded_id`, `slugged_encoded_id`, the `find_by_encoded_id` family, `where_encoded_id`, `encoded_id_config` |
| `EncodedId::Rails::PathParam` | `to_param` returns `encoded_id` |
| `EncodedId::Rails::SluggedPathParam` | `to_param` returns `slugged_encoded_id` |
| `EncodedId::Rails::ActiveRecordFinders` | `find` and `find_by_id` accept encoded IDs (integer primary keys only) |
| `EncodedId::Rails::Persists` | stores encoded IDs in `normalized_encoded_id` and `prefixed_encoded_id` columns |

## Choosing an encoder

Use Sqids (the default) for new applications. Use Hashids (`config.encoder = :hashids`) only to keep IDs issued
by an older version or another Hashids library valid. The two are not compatible: never switch after IDs are public.
With Sqids every model encodes the same number to the same hash; with Hashids each model gets its own salt
(`"ClassName/#{config.salt}"`). See the `encoded-id` skill for the encoders themselves.

## Common mistakes

- **Assigning to the configuration.** `EncodedId::Rails.configuration` is frozen; `configuration.salt = ...`
  raises `FrozenError`. Use `EncodedId::Rails.configure { |config| ... }` at boot, not while serving requests.
  In tests, use `with_encoded_id_configuration` from `EncodedId::Rails::TestHelper`.
- **No salt with Sqids.** Models build a salt from `config.salt` for every encoder and raise
  `StandardError: Encoded ID salt is invalid` when it is missing or under 4 characters. Sqids does not use it.
- **Separators inside the alphabet.** `configure` raises `ArgumentError` at boot if a separator uses an alphabet
  character, or the slug separator equals the group separator.
- **Changing settings after launch.** A new encoder, salt, alphabet, `id_length`, blocklist or group separator
  makes issued IDs stop resolving.
- **Methods that return changing values.** `encoded_id_salt` and `encoded_id_options` are read once per
  configuration; their results are frozen and cached with the model's coder.
- **Expecting the annotation to be checked.** `User.find_by_encoded_id("product_dchf-51kr")` finds user 1. The
  prefix is for people; scope lookups yourself.
- **`where(id: encoded)`.** Only `find` and `find_by_id` are overridden by `ActiveRecordFinders`; use
  `where_encoded_id`. Do not include `ActiveRecordFinders` in models with string or UUID primary keys.
- **Per-model annotation or slug settings.** `annotation_method_name`, `annotated_id_separator`,
  `slug_value_method_name` and `slugged_id_separator` are global; `encoded_id_config` ignores them.

## References

- [references/configuration.md](references/configuration.md): every option, `configure`, per-model
  `encoded_id_config`, salts, STI, caching and the test helper.
- [references/finders.md](references/finders.md): the finder and query methods, `ActiveRecordFinders`, routes and
  controllers.
- [references/slugged-and-annotated-ids.md](references/slugged-and-annotated-ids.md): annotations, slugs,
  `to_param` and memoization.
- [references/persistence.md](references/persistence.md): `Persists`, the columns generator, backfilling.

Full documentation: https://encoded-id.onrender.com/docs/encoded_id_rails/
