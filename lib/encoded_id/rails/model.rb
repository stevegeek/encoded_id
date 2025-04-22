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

        # Automatically include PathParam if configured to do so
        if EncodedId::Rails.configuration.model_to_param_returns_encoded_id
          base.include(EncodedId::Rails::PathParam)
        end
      end

      attr_accessor :encoded_id_memoized_with_id

      def clear_encoded_id_cache!
        [:@encoded_id_hash, :@encoded_id, :@slugged_encoded_id].each do |var|
          remove_instance_variable(var) if instance_variable_defined?(var)
        end
        self.encoded_id_memoized_with_id = nil
      end

      def check_and_clear_memoization
        clear_encoded_id_cache! if encoded_id_memoized_with_id && encoded_id_memoized_with_id != id
      end

      def encoded_id_hash
        return unless id
        check_and_clear_memoization
        return @encoded_id_hash if defined?(@encoded_id_hash)

        self.encoded_id_memoized_with_id = id
        @encoded_id_hash = self.class.encode_encoded_id(id)
      end

      def encoded_id
        return unless id
        check_and_clear_memoization
        return @encoded_id if defined?(@encoded_id)

        encoded = encoded_id_hash
        annotated_by = EncodedId::Rails.configuration.annotation_method_name
        return @encoded_id = encoded unless annotated_by && encoded

        separator = EncodedId::Rails.configuration.annotated_id_separator
        self.encoded_id_memoized_with_id = id
        @encoded_id = EncodedId::Rails::AnnotatedId.new(id_part: encoded, annotation: send(annotated_by.to_s), separator: separator).annotated_id
      end

      def slugged_encoded_id
        return unless id
        check_and_clear_memoization
        return @slugged_encoded_id if defined?(@slugged_encoded_id)

        with = EncodedId::Rails.configuration.slug_value_method_name
        separator = EncodedId::Rails.configuration.slugged_id_separator
        encoded = encoded_id
        return unless encoded

        self.encoded_id_memoized_with_id = id
        @slugged_encoded_id = EncodedId::Rails::SluggedId.new(id_part: encoded, slug_part: send(with.to_s), separator: separator).slugged_id
      end

      def reload(options = nil)
        result = super
        clear_encoded_id_cache!
        result
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

      # When duplicating an ActiveRecord object, we want to reset the memoized encoded IDs
      def dup
        super.tap do |new_record|
          new_record.clear_encoded_id_cache!
        end
      end
    end
  end
end
