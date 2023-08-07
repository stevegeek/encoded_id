# frozen_string_literal: true

module EncodedId
  module Rails
    module EncoderMethods
      def encode_encoded_id(ids, options = {})
        raise StandardError, "You must pass an ID or array of IDs" if ids.blank?
        encoded_id_coder(options).encode(ids)
      end

      def decode_encoded_id(slugged_encoded_id, options = {})
        return if slugged_encoded_id.blank?
        annotated_encoded_id = SluggedIdParser.new(slugged_encoded_id, separator: EncodedId::Rails.configuration.slugged_id_separator).id
        encoded_id = AnnotatedIdParser.new(annotated_encoded_id, separator: EncodedId::Rails.configuration.annotated_id_separator).id
        return if !encoded_id || encoded_id.blank?
        encoded_id_coder(options).decode(encoded_id)
      end

      # This can be overridden in the model to provide a custom salt
      def encoded_id_salt
        # @type self: Class
        EncodedId::Rails::Salt.new(self, EncodedId::Rails.configuration.salt).generate!
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
  end
end
