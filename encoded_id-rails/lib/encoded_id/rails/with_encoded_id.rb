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

        def where_encoded_id(slugged_encoded_id)
          decoded_id = decode_encoded_id(slugged_encoded_id)
          raise ActiveRecord::RecordNotFound if decoded_id.nil?
          where(id: decoded_id)
        end

        def encode_encoded_id(ids, options = {})
          raise StandardError, "You must pass an ID or array of IDs" if ids.blank?
          encoded_id_coder(options).encode(ids)
        end

        def decode_encoded_id(slugged_encoded_id, options = {})
          return if slugged_encoded_id.blank?
          encoded_id = encoded_id_parser(slugged_encoded_id).id
          return if !encoded_id || encoded_id.blank?
          encoded_id_coder(options).decode(encoded_id)
        end

        # This can be overridden in the model to provide a custom salt
        def encoded_id_salt
          EncodedId::Rails::Salt.new(self, EncodedId::Rails.configuration.salt).generate!
        end

        def encoded_id_parser(slugged_encoded_id)
          SluggedIdParser.new(slugged_encoded_id, separator: EncodedId::Rails.configuration.slugged_id_separator)
        end

        def encoded_id_coder(options = {})
          config = EncodedId::Rails.configuration
          EncodedId::Rails::Coder.new(
            salt: options[:salt] || encoded_id_salt,
            id_length: options[:id_length] || config.id_length,
            character_group_size: options[:character_group_size] || config.character_group_size,
            alphabet: options[:alphabet] || config.alphabet,
            separator: options[:separator] || config.group_separator
          )
        end
      end

      # Instance methods

      def encoded_id
        @encoded_id ||= self.class.encode_encoded_id(id)
      end

      def slugged_encoded_id(with: :slug)
        @slugged_encoded_id ||= EncodedId::Rails::SluggedId.new(
          self,
          name_method: with,
          id_method: :encoded_id,
          separator: EncodedId::Rails.configuration.slugged_id_separator
        ).slugged_id
      end

      # By default slug calls `name` if it exists or returns class name
      def slug
        if respond_to? :name
          given_name = name
          return given_name if given_name.present?
        end
        self.class.name&.underscore
      end
    end
  end
end
