# frozen_string_literal: true

require "active_record"
require "encoded_id"

module EncodedId
  module Rails
    module WithEncodedId
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Find by encoded ID and optionally ensure record ID is the same as constraint (can be slugged)
        def find_by_encoded_id(slugged_encoded_id, with_id: nil)
          encoded_id = extract_id_part(slugged_encoded_id)
          decoded_id = decode_encoded_id(encoded_id)
          return nil if decoded_id.nil?
          find_via_custom_id(decoded_id, :id, compare_to: with_id)
        end

        def find_by_encoded_id!(slugged_encoded_id, with_id: nil)
          encoded_id = extract_id_part(slugged_encoded_id)
          decoded_id = decode_encoded_id(encoded_id)
          raise ActiveRecord::RecordNotFound if decoded_id.nil?
          find_via_custom_id!(decoded_id, :id, compare_to: with_id)
        end

        # Find by a fixed slug value (assumed as an attribute value in the DB)
        def find_by_fixed_slug(slug, attribute: :slug, with_id: nil)
          find_via_custom_id(slug, attribute, compare_to: with_id)
        end

        def find_by_fixed_slug!(slug, attribute: :slug, with_id: nil)
          find_via_custom_id!(slug, attribute, compare_to: with_id)
        end

        # Find by record ID where the ID has been slugged
        def find_by_slugged_id(slugged_id, with_id: nil)
          id_part = decode_slugged_ids(slugged_id)
          unless with_id.nil?
            return unless with_id == id_part
          end
          where(id: id_part)&.first
        end

        def find_by_slugged_id!(slugged_id, with_id: nil)
          id_part = decode_slugged_ids(slugged_id)
          unless with_id.nil?
            raise ActiveRecord::RecordNotFound unless with_id == id_part
          end
          find(id_part)
        end

        # relation helpers

        def where_encoded_id(slugged_encoded_id)
          decoded_id = decode_encoded_id(extract_id_part(slugged_encoded_id))
          raise ActiveRecord::RecordNotFound if decoded_id.nil?
          where(id: decoded_id)
        end

        def where_fixed_slug(slug, attribute: :slug)
          where(attribute => slug)
        end

        def where_slugged_id(slugged_id)
          id_part = decode_slugged_ids(slugged_id)
          raise ActiveRecord::RecordNotFound if id_part.nil?
          where(id: id_part)
        end

        # Encode helpers

        def encode_encoded_id(id, options = {})
          raise StandardError, "You must pass an ID" if id.blank?
          hash_id_encoder(options).encode(id)
        end

        def encode_multi_encoded_id(encoded_ids, options = {})
          raise ::StandardError, "You must pass IDs" if encoded_ids.blank?
          hash_id_encoder(options).encode(encoded_ids)
        end

        # Decode helpers

        # Decode a encoded_id (can be slugged)
        def decode_encoded_id(slugged_encoded_id, options = {})
          internal_decode_encoded_id(slugged_encoded_id, options)&.first
        end

        def decode_multi_encoded_id(slugged_encoded_id, options = {})
          internal_decode_encoded_id(slugged_encoded_id, options)
        end

        # Decode a Slugged ID
        def decode_slugged_id(slugged)
          return if slugged.blank?
          extract_id_part(slugged).to_i
        end

        # Decode a set of slugged IDs
        def decode_slugged_ids(slugged)
          return if slugged.blank?
          extract_id_part(slugged).split("-").map(&:to_i)
        end

        # This can be overridden in the model to provide a custom salt
        def encoded_id_salt
          unless config && config.salt.present?
            raise ::StandardError, "You must set a model specific encoded_id_salt or a gem wide one"
          end
          unless name.present?
            raise ::StandardError, "The class must have a name to ensure encode id uniqueness. " \
              "Please set a name on the class or override `encoded_id_salt`."
          end
          salt = config.salt
          raise ::StandardError, "Encoded ID salt is invalid" if salt.blank? || salt.size < 4
          "#{name}/#{salt}"
        end

        private

        def hash_id_encoder(options)
          ::EncodedId::ReversibleId.new(
            salt: options[:salt].presence || encoded_id_salt,
            length: options[:id_length] || config.id_length,
            split_at: options[:character_group_size] || config.character_group_size,
            alphabet: options[:alphabet] || config.alphabet
          )
        end

        def config
          ::EncodedId::Rails.configuration
        end

        def internal_decode_encoded_id(slugged_encoded_id, options)
          return if slugged_encoded_id.blank?
          encoded_id = extract_id_part(slugged_encoded_id)
          return if encoded_id.blank?
          hash_id_encoder(options).decode(encoded_id)
        rescue EncodedId::EncodedIdFormatError
          nil
        end

        def find_via_custom_id(value, attribute, compare_to: nil)
          return if value.blank?
          record = find_by({attribute => value})
          return unless record
          unless compare_to.nil?
            return unless compare_to == record.send(attribute)
          end
          record
        end

        def find_via_custom_id!(value, attribute, compare_to: nil)
          raise ::ActiveRecord::RecordNotFound if value.blank?
          record = find_by!({attribute => value})
          unless compare_to.nil?
            raise ::ActiveRecord::RecordNotFound unless compare_to == record.send(attribute)
          end
          record
        end

        def extract_id_part(slugged_id)
          return if slugged_id.blank?
          has_slug = slugged_id.include?("--")
          return slugged_id unless has_slug
          split_slug = slugged_id.split("--")
          split_slug.last if has_slug && split_slug.size > 1
        end
      end

      # Instance methods

      def encoded_id
        @encoded_id ||= self.class.encode_encoded_id(id)
      end

      # (slug)--(hash id)
      def slugged_encoded_id(with: :slug)
        @slugged_encoded_id ||= generate_composite_id(with, :encoded_id)
      end

      # (name slug)--(record id(s) (separated by hyphen))
      def slugged_id(with: :slug)
        @slugged_id ||= generate_composite_id(with, :id)
      end

      # By default slug calls `name` if it exists or returns class name
      def slug
        klass = self.class.name&.underscore
        return klass unless respond_to? :name
        given_name = name
        return given_name if given_name.present?
        klass
      end

      private

      def generate_composite_id(name_method, id_method)
        name_part = send(name_method)
        id_part = send(id_method)
        unless id_part.present? && name_part.present?
          raise(::StandardError, "The model has no #{id_method} or #{name_method}")
        end
        "#{name_part.to_s.parameterize}--#{id_part}"
      end
    end
  end
end
