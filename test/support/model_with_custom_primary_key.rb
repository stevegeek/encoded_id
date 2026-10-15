# frozen_string_literal: true

class Widget < ::ActiveRecord::Base
  self.primary_key = :widget_id

  include EncodedId::Rails::Model

  def name_for_encoded_id_slug
    name
  end
end

class WidgetWithIdColumn < ::ActiveRecord::Base
  self.primary_key = :widget_id

  include EncodedId::Rails::Model
end
