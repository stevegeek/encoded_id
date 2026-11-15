# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Provides methods for encoding and decoding IDs, extended into ActiveRecord models.
    module EncoderMethods
      # @rbs!
      #   def primary_key: () -> (String | Array[String] | nil)

      # @rbs @encoded_id_coder: [EncodedId::Rails::Configuration, Hash[Symbol, untyped], EncodedId::Rails::Coder]?

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
      #   | (_EncodedIdModel self, ?Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def encoded_id_coder(options = {})
        config = EncodedId::Rails.configuration
        model_options = encoded_id_model_options
        return build_encoded_id_coder(config, model_options.merge(options)) unless options.empty?

        cached_config, cached_options, coder = @encoded_id_coder
        return coder if coder && cached_config.equal?(config) && cached_options == model_options

        coder = build_encoded_id_coder(config, model_options)
        # One assignment, so threads racing here at worst each build a coder.
        @encoded_id_coder = [config, model_options, coder]
        coder
      end

      private

      # @rbs (EncodedId::Rails::Configuration config, Hash[Symbol, untyped] options) -> EncodedId::Rails::Coder
      def build_encoded_id_coder(config, options)
        settings = EncodedId::Rails::Coder::Settings.resolve(configuration: config, options: options) do
          encoded_id_salt.freeze
        end
        EncodedId::Rails::Coder.new(settings)
      end

      # @rbs () -> Hash[Symbol, untyped]
      #   | (_EncodedIdModel self) -> Hash[Symbol, untyped]
      def encoded_id_model_options
        return {}.freeze unless respond_to?(:encoded_id_options)
        options = encoded_id_options #: Hash[Symbol, untyped]
        options.each_value(&:freeze).freeze
      end
    end
  end
end
