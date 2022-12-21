# frozen_string_literal: true

module EncodedId
  module Rails
    module FinderMethods
      # Find by encoded ID and optionally ensure record ID is the same as constraint (can be slugged)
      def find_by_encoded_id(slugged_encoded_id, with_id: nil)
        decoded_id = decode_encoded_id(slugged_encoded_id)
        return if decoded_id.blank?
        record = find_by(id: decoded_id)
        return unless record
        return if with_id && with_id != record.send(:id)
        record
      end

      def find_by_encoded_id!(slugged_encoded_id, with_id: nil)
        decoded_id = decode_encoded_id(slugged_encoded_id)
        raise ActiveRecord::RecordNotFound if decoded_id.blank?
        record = find_by(id: decoded_id)
        if !record || (with_id && with_id != record.send(:id))
          raise ActiveRecord::RecordNotFound
        end
        record
      end
    end
  end
end
