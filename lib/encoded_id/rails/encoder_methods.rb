# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    module EncoderMethods
      # @rbs (Array[Integer] | Integer ids, Hash[Symbol, untyped] options) -> String
      def encode_encoded_id(ids, options = {})
        raise StandardError, "You must pass an ID or array of IDs" if ids.blank?
        encoded_id_coder(options).encode(ids)
      end

      # @rbs (String slugged_encoded_id, Hash[Symbol, untyped] options) -> Array[Integer]?
      def decode_encoded_id(slugged_encoded_id, options = {})
        return if slugged_encoded_id.blank?
        raise StandardError, "You must pass a string encoded ID" unless slugged_encoded_id.is_a?(String)
        annotated_encoded_id = SluggedIdParser.new(slugged_encoded_id, separator: EncodedId::Rails.configuration.slugged_id_separator).id
        encoded_id = AnnotatedIdParser.new(annotated_encoded_id, separator: EncodedId::Rails.configuration.annotated_id_separator).id
        return if !encoded_id || encoded_id.blank?
        encoded_id_coder(options).decode(encoded_id)
      end

      # This can be overridden in the model to provide a custom salt
      # @rbs return: String
      def encoded_id_salt
        # @type self: Class
        EncodedId::Rails::Salt.new(self, EncodedId::Rails.configuration.salt).generate!
      end

      # @rbs (?Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def encoded_id_coder(options = {})
        config = EncodedId::Rails.configuration
        EncodedId::Rails::Coder.new(
          salt: options[:salt] || encoded_id_salt,
          id_length: options[:id_length] || config.id_length,
          character_group_size: options.key?(:character_group_size) ? options[:character_group_size] : config.character_group_size,
          alphabet: options[:alphabet] || config.alphabet,
          separator: options.key?(:separator) ? options[:separator] : config.group_separator,
          encoder: options[:encoder] || config.encoder,
          blocklist: options[:blocklist] || config.blocklist
        )
      end
    end
  end
end
