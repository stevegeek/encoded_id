# frozen_string_literal: true

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module Model
      def self.included(base)
        base.extend(EncoderMethods)
        base.extend(FinderMethods)
        base.extend(QueryMethods)
      end

      def encoded_id
        return unless id
        return @encoded_id if defined?(@encoded_id) && !id_changed?
        @encoded_id = self.class.encode_encoded_id(id)
      end

      def slugged_encoded_id(with: :name_for_encoded_id_slug)
        return unless id
        return @slugged_encoded_id if defined?(@slugged_encoded_id) && !id_changed?
        @slugged_encoded_id = EncodedId::Rails::SluggedId.new(
          self,
          slug_method: with,
          id_method: :encoded_id,
          separator: EncodedId::Rails.configuration.slugged_id_separator
        ).slugged_id
      end

      # By default slug created from class name, but can be overridden
      def name_for_encoded_id_slug
        class_name = self.class.name
        raise StandardError, "Class must have a `name`, cannot create a slug" if !class_name || class_name.blank?
        class_name.underscore
      end

      # When duplicating an ActiveRecord object, we want to reset the memoized encoded_id
      def dup
        super.tap do |new_record|
          new_record.instance_variable_set(:@encoded_id, nil)
          new_record.instance_variable_set(:@slugged_encoded_id, nil)
        end
      end
    end
  end
end
