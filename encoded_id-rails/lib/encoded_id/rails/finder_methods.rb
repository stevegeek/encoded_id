# frozen_string_literal: true

module EncodedId
  module Rails
    module FinderMethods
      # Find by encoded ID and optionally ensure record ID is the same as constraint (can be slugged)
      def find_by_encoded_id(encoded_id, with_id: nil)
        decoded_id = decode_encoded_id(encoded_id)
        return if decoded_id.nil? || decoded_id.blank?
        record = find_by(id: decoded_id.first)
        return unless record
        return if with_id && with_id != record.send(:id)
        record
      end

      def find_by_encoded_id!(encoded_id, with_id: nil)
        decoded_id = decode_encoded_id(encoded_id)
        raise ActiveRecord::RecordNotFound if decoded_id.nil? || decoded_id.blank?
        record = find_by(id: decoded_id.first)
        if !record || (with_id && with_id != record.send(:id))
          raise ActiveRecord::RecordNotFound
        end
        record
      end

      def find_all_by_encoded_id(encoded_id)
        decoded_ids = decode_encoded_id(encoded_id)
        return if decoded_ids.blank?
        where(id: decoded_ids).to_a
      end

      def find_all_by_encoded_id!(encoded_id)
        decoded_ids = decode_encoded_id(encoded_id)
        raise ActiveRecord::RecordNotFound if decoded_ids.nil? || decoded_ids.blank?
        records = where(id: decoded_ids).to_a
        raise ActiveRecord::RecordNotFound if records.blank? || records.size != decoded_ids.size
        records
      end
    end
  end
end
