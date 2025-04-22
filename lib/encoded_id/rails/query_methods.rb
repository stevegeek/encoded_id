# frozen_string_literal: true

module EncodedId
  module Rails
    module QueryMethods
      def where_encoded_id(slugged_encoded_id)
        decoded_id = decode_encoded_id(slugged_encoded_id)
        raise ActiveRecord::RecordNotFound if decoded_id.nil?
        where(id: decoded_id)
      end
    end
  end
end
