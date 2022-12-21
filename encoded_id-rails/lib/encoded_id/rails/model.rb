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
        @encoded_id ||= self.class.encode_encoded_id(id)
      end

      def slugged_encoded_id(with: :name_for_encoded_id_slug)
        @slugged_encoded_id ||= EncodedId::Rails::SluggedId.new(
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
    end
  end
end
