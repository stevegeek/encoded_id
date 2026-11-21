# Persisting encoded IDs

`EncodedId::Rails::Persists` stores each record's encoded ID in two columns, so other systems (SQL reports, search
indexes, support tools) can look records up by encoded ID without the Ruby coder.

| Column | Holds | Example |
|---|---|---|
| `normalized_encoded_id` | the hash without group separators or annotation | `dchf51kr` |
| `prefixed_encoded_id` | `encoded_id`, with the annotation and separators | `user_dchf-51kr` |

## Setup

```bash
bin/rails generate encoded_id:rails:add_columns User        # several models: add_columns User Order
bin/rails db:migrate
```

The migration adds both string columns and a unique index on each.

```ruby
class User < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::Persists
end
```

## Behaviour

- `after_create` writes both columns with `update_columns`, once the record has an ID.
- `before_save` sets them again if the ID changed, or if they are blank on a persisted record.
- `after_commit` (create and update) raises `StandardError` if the stored values differ from the values the
  current configuration computes. A configuration change that alters encoded IDs therefore fails on the next save
  of an existing record until its columns are rewritten.
- Both columns are validated for uniqueness (`nil` allowed).
- Assigning either column yourself raises `ActiveRecord::ReadonlyAttributeError` on validation.
- `dup` sets both columns to `nil` on the copy without marking them changed; they are written when it is saved.

Methods:

- `set_normalized_encoded_id!`: writes both columns now with `update_columns` (no callbacks or validations).
- `update_normalized_encoded_id!`: assigns both columns in memory; they are written by the next `save`.

Both raise `StandardError` for a record without an ID.

## Lookups

```ruby
User.where(normalized_encoded_id: "dchf51kr").first
User.find_by(prefixed_encoded_id: "user_dchf-51kr")
```

These compare strings exactly; they do not map look-alike characters or remove separators as decoding does.
Normalize input first, or use `find_by_encoded_id`, which decodes and needs no columns.

## Backfilling existing records

```ruby
User.where(normalized_encoded_id: nil).find_each do |user|
  user.set_normalized_encoded_id!
end
```

Run it after the migration and before relying on the columns. For large tables, run it in batches from a job.

## Changing the configuration later

If the encoder, salt, alphabet, `id_length`, annotation or separators change, stored values become stale and the
`after_commit` check raises on the next save. Rewrite every row with `set_normalized_encoded_id!` as part of the
change, and remember that issued IDs stop resolving anyway.
