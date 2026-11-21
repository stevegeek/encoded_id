# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # Encodes and decodes IDs using the configured encoder and settings.
    class Coder
      # The resolved settings a coder is built from.
      Settings = Data.define(
        :salt, #: String?
        :id_length, #: Integer
        :max_length, #: Integer?
        :max_inputs_per_id, #: Integer
        :hex_digit_encoding_group_size, #: Integer
        :hex_encoding, #: Symbol
        :character_group_size, #: Integer?
        :separator, #: String?
        :alphabet, #: ::EncodedId::Alphabet
        :encoder, #: Symbol
        :blocklist, #: ::EncodedId::Blocklist?
        :blocklist_mode, #: Symbol
        :blocklist_max_length, #: Integer
        :downcase_on_decode #: bool
      ) do
        # `max_length`, `character_group_size`, `separator` and `downcase_on_decode` can be set to nil or false in options.
        def self.resolve(configuration:, salt:, options: {})
          new(
            salt: salt,
            id_length: options[:id_length] || configuration.id_length,
            max_length: options.key?(:max_length) ? options[:max_length] : configuration.max_length,
            max_inputs_per_id: options[:max_inputs_per_id] || configuration.max_inputs_per_id,
            hex_digit_encoding_group_size: options[:hex_digit_encoding_group_size] || configuration.hex_digit_encoding_group_size,
            hex_encoding: options[:hex_encoding] || configuration.hex_encoding,
            character_group_size: options.key?(:character_group_size) ? options[:character_group_size] : configuration.character_group_size,
            separator: options.key?(:separator) ? options[:separator] : configuration.group_separator,
            alphabet: options[:alphabet] || configuration.alphabet,
            encoder: options[:encoder] || configuration.encoder,
            blocklist: options[:blocklist] || configuration.blocklist,
            blocklist_mode: options[:blocklist_mode] || configuration.blocklist_mode,
            blocklist_max_length: options[:blocklist_max_length] || configuration.blocklist_max_length,
            downcase_on_decode: options.key?(:downcase_on_decode) ? options[:downcase_on_decode] : configuration.downcase_on_decode
          )
        end
      end

      # @rbs!
      #   class Settings
      #     def self.resolve: (configuration: EncodedId::Rails::Configuration, salt: String?, ?options: Hash[Symbol, untyped]) -> Settings
      #   end

      # @rbs @settings: Settings
      # @rbs @coder: ::EncodedId::ReversibleId

      attr_reader :settings #: Settings

      # @rbs (Settings settings) -> void
      def initialize(settings)
        @settings = settings
        @coder = build_coder
      end

      # @rbs (Integer | Array[Integer] id) -> String
      def encode(id)
        @coder.encode(id)
      end

      # @rbs (String encoded_id) -> Array[Integer]
      def decode(encoded_id)
        @coder.decode(encoded_id, downcase: settings.downcase_on_decode)
      rescue EncodedId::EncodedIdFormatError, EncodedId::InvalidInputError
        []
      end

      private

      # @rbs return: ::EncodedId::ReversibleId
      def build_coder
        s = settings
        options = {
          min_length: s.id_length,
          max_length: s.max_length,
          max_inputs_per_id: s.max_inputs_per_id,
          hex_digit_encoding_group_size: s.hex_digit_encoding_group_size,
          hex_encoding: s.hex_encoding,
          split_at: s.character_group_size,
          split_with: s.separator,
          alphabet: s.alphabet,
          blocklist: s.blocklist,
          blocklist_mode: s.blocklist_mode,
          blocklist_max_length: s.blocklist_max_length
        }
        config = case s.encoder
        when :hashids
          ::EncodedId::Encoders::HashidConfiguration.new(
            salt: s.salt || raise(ArgumentError, "Salt is required for hashids encoder"),
            **options
          )
        when :sqids
          ::EncodedId::Encoders::SqidsConfiguration.new(**options)
        else
          raise ArgumentError, "Unknown encoder type: #{s.encoder}"
        end

        ::EncodedId::ReversibleId.new(config)
      end
    end
  end
end
