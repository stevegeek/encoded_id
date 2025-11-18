# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :my_models, force: true do |t|
    t.column :name, :string
    t.column :foo, :string
    t.timestamps
  end

  create_table :model_with_persisted_encoded_ids, force: true do |t|
    t.column :foo, :string
    t.column :normalized_encoded_id, :string
    t.column :prefixed_encoded_id, :string
    t.timestamps
  end

  create_table :sti_records, force: true do |t|
    t.column :type, :string
    t.column :name, :string
    t.timestamps
  end
end
