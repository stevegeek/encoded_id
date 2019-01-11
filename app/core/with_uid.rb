# frozen_string_literal: true

module Core
  module WithUid
    extend ActiveSupport::Concern

    module ClassMethods
      # Find by UID and optionally ensure record ID is the same as constraint
      def find_by_uid(uid, with_id: nil)
        record = find_by(id: Core::ReversableId.decode(uid))
        return unless record
        unless with_id.nil?
          return unless with_id == record.id
        end
        record
      end

      def find_by_uid!(uid, with_id: nil)
        record = find_by(id: Core::ReversableId.decode(uid))
        raise ActiveRecord::RecordNotFound unless record
        unless with_id.nil?
          raise ActiveRecord::RecordNotFound unless with_id == record.id
        end
        record
      end
    end

    def uid
      return unless id
      Core::ReversableId.encode(id)
    end
  end
end
