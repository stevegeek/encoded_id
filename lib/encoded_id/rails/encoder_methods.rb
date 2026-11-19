# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Provides methods for encoding and decoding IDs, extended into ActiveRecord models.
    module EncoderMethods
      # @rbs!
      #   def primary_key: () -> (String | Array[String] | nil)
      #   def encoded_id_options: () -> Hash[Symbol, untyped]

      # @rbs @encoded_id_coder: [EncodedId::Rails::Configuration, Hash[Symbol, untyped], EncodedId::Rails::Coder]?

      # @rbs (Array[Integer] | Integer ids, ?Hash[Symbol, untyped] options) -> String
      def encode_encoded_id(ids, options = {})
        raise StandardError, "You must pass an ID or array of IDs" if ids.blank?
        encoded_id_coder(options).encode(ids)
      end

      # @rbs (String slugged_encoded_id, ?Hash[Symbol, untyped] options) -> Array[Integer]?
      def decode_encoded_id(slugged_encoded_id, options = {})
        return [] if slugged_encoded_id.is_a?(String) && !slugged_encoded_id.valid_encoding?
        return if slugged_encoded_id.blank?
        raise StandardError, "You must pass a string encoded ID" unless slugged_encoded_id.is_a?(String)
        config = EncodedId::Rails.configuration
        annotated_encoded_id = SluggedIdParser.new(slugged_encoded_id, separator: config.slugged_id_separator).id
        encoded_id = AnnotatedIdParser.new(annotated_encoded_id, separator: config.annotated_id_separator).id
        return if !encoded_id || encoded_id.blank?
        encoded_id_coder(options).decode(encoded_id)
      end

      # Composite and missing primary keys are not supported, so lookups fall back to the `id` column for them.
      # @rbs () -> String
      def encoded_id_primary_key
        key = primary_key
        key.is_a?(String) ? key : "id"
      end

      # This can be overridden in the model to provide a custom salt
      # @rbs return: String
      def encoded_id_salt
        # @type self: Class
        EncodedId::Rails::Salt.new(self, EncodedId::Rails.configuration.salt).generate!
      end

      # Without call-time options the coder is reused until the configuration or the model's
      # `encoded_id_options` change. The salt and options a model gives are frozen when the coder is built,
      # so an `encoded_id_salt` override is read once per configuration.
      # @rbs (?Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def encoded_id_coder(options = {})
        config = EncodedId::Rails.configuration
        model_options = encoded_id_model_options
        return build_encoded_id_coder(config, model_options.merge(options)) unless options.empty?

        coder = cached_coder(config, model_options)
        return coder if coder

        # No lock: building runs model code (`encoded_id_salt`), which must not run under a lock it could
        # deadlock with. Threads racing here each build an equal coder and the last assignment wins.
        coder = build_encoded_id_coder(config, model_options)
        @encoded_id_coder = [config, model_options, coder]
        coder
      end

      private

      # @rbs (EncodedId::Rails::Configuration config, Hash[Symbol, untyped] model_options) -> EncodedId::Rails::Coder?
      def cached_coder(config, model_options)
        cached_config, cached_options, coder = @encoded_id_coder
        coder if cached_config.equal?(config) && cached_options == model_options
      end

      # @rbs (EncodedId::Rails::Configuration config, Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def build_encoded_id_coder(config, options)
        salt = options[:salt] || encoded_id_salt.freeze
        EncodedId::Rails::Coder.new(EncodedId::Rails::Coder::Settings.resolve(configuration: config, salt: salt, options: options))
      end

      # @rbs () -> Hash[Symbol, untyped]
      def encoded_id_model_options
        options = respond_to?(:encoded_id_options) ? encoded_id_options : {} #: Hash[Symbol, untyped]
        options.each_value(&:freeze).freeze
      end
    end
  end
end
