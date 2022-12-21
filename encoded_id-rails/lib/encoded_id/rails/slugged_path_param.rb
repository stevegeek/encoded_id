# frozen_string_literal: true

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module SluggedPathParam
      def to_param
        slugged_encoded_id
      end
    end
  end
end
