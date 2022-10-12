# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :my_models, force: true do |t|
    t.column :foo, :string
    t.datetime :created_at
    t.datetime :updated_at
  end
end
