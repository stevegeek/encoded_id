# frozen_string_literal: true
# rbs_inline: enabled

module EncodedId
  module Rails
    module Persists
      # @rbs (untyped base) -> void
      def self.included(base)
        base.extend ClassMethods

        base.validates :normalized_encoded_id, uniqueness: true, allow_nil: true
        base.validates :prefixed_encoded_id, uniqueness: true, allow_nil: true

        base.before_validation :prevent_update_of_normalized_encoded_id!, if: :normalized_encoded_id_changed?
        base.before_validation :prevent_update_of_prefixed_encoded_id!, if: :prefixed_encoded_id_changed?

        base.after_create :set_normalized_encoded_id!
        base.before_save :update_normalized_encoded_id!, if: :should_update_normalized_encoded_id?

        base.after_commit :check_encoded_id_persisted!, on: [:create, :update]
      end

      module ClassMethods
        # @rbs (Integer id) -> String
        def encode_normalized_encoded_id(id)
          encode_encoded_id(id, character_group_size: nil)
        end
      end

      # On duplication we need to reset the encoded ID to nil as this new record will have a new ID.
      # We need to also prevent these changes from marking the record as dirty.
      # @rbs () -> untyped
      def dup
        copy = super
        copy.prefixed_encoded_id = nil
        copy.clear_prefixed_encoded_id_change
        copy.normalized_encoded_id = nil
        copy.clear_normalized_encoded_id_change
        copy
      end

      # @rbs () -> void
      def set_normalized_encoded_id!
        validate_id_for_encoded_id!

        update_columns(normalized_encoded_id: self.class.encode_normalized_encoded_id(id), prefixed_encoded_id: encoded_id)
      end

      # @rbs () -> void
      def update_normalized_encoded_id!
        validate_id_for_encoded_id!

        self.normalized_encoded_id = self.class.encode_normalized_encoded_id(id)
        self.prefixed_encoded_id = encoded_id
      end

      # @rbs () -> void
      def check_encoded_id_persisted!
        if normalized_encoded_id != self.class.encode_normalized_encoded_id(id)
          raise StandardError, "The persisted encoded ID #{normalized_encoded_id} for #{self.class.name} is not the same as currently computing #{self.class.encode_normalized_encoded_id(id)}"
        end

        raise StandardError, "The persisted prefixed encoded ID (for #{self.class.name} with id: #{id}, normalized_encoded_id: #{normalized_encoded_id}) is not correct: it is #{prefixed_encoded_id} instead of #{encoded_id}" if prefixed_encoded_id != encoded_id
      end

      # @rbs () -> bool
      def should_update_normalized_encoded_id?
        id_changed? || (normalized_encoded_id.blank? && persisted?)
      end

      # @rbs () -> void
      def validate_id_for_encoded_id!
        raise StandardError, "You cannot set the normalized ID of a record which is not persisted" if id.blank?
      end

      # @rbs () -> void
      def prevent_update_of_normalized_encoded_id!
        raise ActiveRecord::ReadonlyAttributeError, "You cannot update the normalized encoded ID '#{normalized_encoded_id}' of a record #{self.class.name} #{id}, if you need to refresh it use set_normalized_encoded_id!"
      end

      # @rbs () -> void
      def prevent_update_of_prefixed_encoded_id!
        raise ActiveRecord::ReadonlyAttributeError, "You cannot update the prefixed encoded ID '#{prefixed_encoded_id}' of a record #{self.class.name} #{id}, if you need to refresh it use set_normalized_encoded_id!"
      end
    end
  end
end
