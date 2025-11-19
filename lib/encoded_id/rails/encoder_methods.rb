# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Provides methods for encoding and decoding IDs, extended into ActiveRecord models.
    module EncoderMethods
      # @rbs!
      #   interface _EncodedIdModel
      #     def encoded_id_options: () -> Hash[Symbol, untyped]
      #   end
      # @rbs (Array[Integer] | Integer ids, ?Hash[Symbol, untyped] options) -> String
      def encode_encoded_id(ids, options = {})
        raise StandardError, "You must pass an ID or array of IDs" if ids.blank?
        encoded_id_coder(options).encode(ids)
      end

      # @rbs (String slugged_encoded_id, ?Hash[Symbol, untyped] options) -> Array[Integer]?
      def decode_encoded_id(slugged_encoded_id, options = {})
        return if slugged_encoded_id.blank?
        raise StandardError, "You must pass a string encoded ID" unless slugged_encoded_id.is_a?(String)
        config = EncodedId::Rails.configuration
        annotated_encoded_id = SluggedIdParser.new(slugged_encoded_id, separator: config.slugged_id_separator).id
        encoded_id = AnnotatedIdParser.new(annotated_encoded_id, separator: config.annotated_id_separator).id
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
      #   | (_EncodedIdModel self, ?Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def encoded_id_coder(options = {})
        config = EncodedId::Rails.configuration
        # Merge model-level options with call-time options (call-time options take precedence)
        # @type var model_options: Hash[Symbol, untyped]
        model_options = respond_to?(:encoded_id_options) ? encoded_id_options : {} #: Hash[Symbol, untyped]
        merged_options = model_options.merge(options)

        EncodedId::Rails::Coder.new(
          salt: merged_options[:salt] || encoded_id_salt,
          id_length: merged_options[:id_length] || config.id_length,
          character_group_size: merged_options.key?(:character_group_size) ? merged_options[:character_group_size] : config.character_group_size,
          alphabet: merged_options[:alphabet] || config.alphabet,
          separator: merged_options.key?(:separator) ? merged_options[:separator] : config.group_separator,
          encoder: merged_options[:encoder] || config.encoder,
          blocklist: merged_options[:blocklist] || config.blocklist,
          blocklist_mode: merged_options[:blocklist_mode] || config.blocklist_mode,
          blocklist_max_length: merged_options[:blocklist_max_length] || config.blocklist_max_length,
          downcase_on_decode: merged_options.key?(:downcase_on_decode) ? merged_options[:downcase_on_decode] : config.downcase_on_decode
        )
      end
    end
  end
end
