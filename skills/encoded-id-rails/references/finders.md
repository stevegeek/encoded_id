# Finders, queries, routes and controllers

All of these accept a plain hash (`dchf-51kr`), an annotated ID (`user_dchf-51kr`) or a slugged ID
(`jane-doe--user_dchf-51kr`). The slug and the annotation are stripped and not checked, so
`User.find_by_encoded_id("product_dchf-51kr")` finds user 1. Lookups use the model's primary key, including a
custom integer one (`self.primary_key = :widget_id`); models without a single-column primary key use `id`.

Strings that are not valid encoded IDs, including ones longer than `max_length`, behave like IDs of missing records:
they do not raise format errors.

## Methods from EncodedId::Rails::Model

| Method | Returns |
|---|---|
| `find_by_encoded_id(encoded_id)` | The record for the first decoded ID, or `nil` |
| `find_by_encoded_id!(encoded_id)` | The record, or raises `ActiveRecord::RecordNotFound` |
| `find_all_by_encoded_id(encoded_id)` | An array of the records for all decoded IDs (in database order, missing ones left out), or `nil` if nothing decodes |
| `find_all_by_encoded_id!(encoded_id)` | The records, or raises `RecordNotFound` if nothing decodes or any record is missing |
| `where_encoded_id(*encoded_ids)` | A relation for all decoded IDs; accepts several IDs or an array |
| `encode_encoded_id(id_or_ids, options = {})` | The hash for one ID or an array of IDs, without annotation |
| `decode_encoded_id(encoded_id, options = {})` | An array of IDs (`[]` if it does not decode), or `nil` for a blank string |

```ruby
User.find_by_encoded_id("user_dchf-51kr")       # => #<User id: 1>
User.find_by_encoded_id("nope")                 # => nil
User.find_by_encoded_id!("nope")                # raises ActiveRecord::RecordNotFound

ids = User.encode_encoded_id([1, 3])            # one encoded ID holding two IDs
User.find_all_by_encoded_id(ids)                # => [#<User id: 1>, #<User id: 3>]

User.where_encoded_id("user_dchf-51kr", "user_rggj-qyes").where(active: true)
User.where_encoded_id("nope").to_a              # => []
```

`where_encoded_id` raises `RecordNotFound` when called with no IDs or a blank one. `encode_encoded_id` raises
`StandardError` for a blank ID, and `decode_encoded_id` for a non-string argument.

## EncodedId::Rails::ActiveRecordFinders

Makes `find` and `find_by_id` accept encoded IDs, so controllers can keep `Model.find(params[:id])`:

```ruby
class Product < ApplicationRecord
  include EncodedId::Rails::Model
  include EncodedId::Rails::ActiveRecordFinders
end

Product.find("product_dchf-51kr")        # => #<Product id: 1>
Product.find(1)                          # integers work as before
Product.find(Product.encode_encoded_id([1, 2]))   # => [#<Product id: 1>, #<Product id: 2>]
Product.find_by_id("product_dchf-51kr")  # => #<Product id: 1>, or nil
```

- Every string passed to `find` is decoded, so `Product.find("1")` raises `RecordNotFound`. Convert numeric strings
  yourself if both forms reach `find`.
- Only `find` and `find_by_id` change. `where(id: "...")`, `find_by(id: "...")` and `exists?("...")` still take raw
  IDs; use `where_encoded_id`.
- Use it only with integer primary keys. It logs a warning when included in a model whose primary key is a string,
  another non-integer type, composite or missing.

## Routes and controllers

With `PathParam` or `SluggedPathParam`, URL helpers emit encoded IDs and the standard `:id` param carries them:

```ruby
# config/routes.rb
resources :users

# app/controllers/users_controller.rb
def show
  @user = User.find_by_encoded_id!(params[:id])   # RecordNotFound renders a 404
end
```

`find_by_encoded_id!` accepts both the slugged and the plain form, so links with an old slug keep working. To
redirect to the current slug, compare `params[:id]` with `@user.to_param`.

Without the path param modules, name the param yourself:

```ruby
resources :users, param: :encoded_id
User.find_by_encoded_id!(params[:encoded_id])
link_to "Profile", user_path(encoded_id: user.encoded_id)
```

The encoded ID is not a permission check: scope the lookup (`current_account.users.find_by_encoded_id!(...)` works,
as these are class methods available on relations) or authorize the record.
