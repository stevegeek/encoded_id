# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :my_models, force: true do |t|
    t.column :foo, :string
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :model_with_persisted_encoded_ids, force: true do |t|
    t.column :foo, :string
    t.column :normalized_encoded_id, :string
    t.column :prefixed_encoded_id, :string
    t.datetime :created_at
    t.datetime :updated_at
  end
end
