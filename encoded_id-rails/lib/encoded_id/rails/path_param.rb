# frozen_string_literal: true

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module PathParam
      def to_param
        encoded_id
      end
    end
  end
end
