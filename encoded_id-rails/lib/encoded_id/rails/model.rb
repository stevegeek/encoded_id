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

      def encoded_id_hash
        return unless id
        return @encoded_id_hash if defined?(@encoded_id_hash) && !id_changed?
        self.class.encode_encoded_id(id)
      end

      def encoded_id
        return unless id
        return @encoded_id if defined?(@encoded_id) && !id_changed?
        encoded = encoded_id_hash
        annotated_by = EncodedId::Rails.configuration.annotation_method_name
        return @encoded_id = encoded unless annotated_by && encoded
        separator = EncodedId::Rails.configuration.annotated_id_separator
        @encoded_id = EncodedId::Rails::AnnotatedId.new(id_part: encoded, annotation: send(annotated_by.to_s), separator: separator).annotated_id
      end

      def slugged_encoded_id
        return unless id
        return @slugged_encoded_id if defined?(@slugged_encoded_id) && !id_changed?
        with = EncodedId::Rails.configuration.slug_method_name
        separator = EncodedId::Rails.configuration.slugged_id_separator
        encoded = encoded_id
        return unless encoded
        @slugged_encoded_id = EncodedId::Rails::SluggedId.new(id_part: encoded, slug_part: send(with.to_s), separator: separator).slugged_id
      end

      # By default the annotation is the model name (it will be parameterized)
      def annotation_for_encoded_id
        name = self.class.name
        raise StandardError, "The default annotation requires the model class to have a name" if name.nil?
        name.underscore
      end

      # By default trying to generate a slug without defining how will raise.
      # You either override this method per model, pass an alternate method name to
      # #slugged_encoded_id or setup an alias to another model method in your ApplicationRecord class
      def name_for_encoded_id_slug
        raise StandardError, "You must define a method to generate the slug for the encoded ID of #{self.class.name}"
      end

      # When duplicating an ActiveRecord object, we want to reset the memoized encoded_id
      def dup
        super.tap do |new_record|
          new_record.send(:remove_instance_variable, :@encoded_id) if new_record.instance_variable_defined?(:@encoded_id)
          new_record.send(:remove_instance_variable, :@slugged_encoded_id) if new_record.instance_variable_defined?(:@slugged_encoded_id)
        end
      end
    end
  end
end
