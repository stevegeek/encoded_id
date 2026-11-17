# frozen_string_literal: true

# rbs_inline: enabled

require_relative "rails/configuration"
require_relative "rails/coder"
require_relative "rails/composite_id_base"
require_relative "rails/slugged_id"
require_relative "rails/slugged_id_parser"
require_relative "rails/annotated_id"
require_relative "rails/annotated_id_parser"
require_relative "rails/salt"
require_relative "rails/encoder_methods"
require_relative "rails/query_methods"
require_relative "rails/finder_methods"
require_relative "rails/path_param"
require_relative "rails/slugged_path_param"
require_relative "rails/model"
require_relative "rails/persists"
require_relative "rails/active_record_finders"
require_relative "rails/railtie"

module EncodedId
  # Rails integration for EncodedId, providing configuration and ActiveRecord extensions.
  module Rails
    # Configuration
    # @rbs self.@configuration: EncodedId::Rails::Configuration?

    class << self
      # The configuration is frozen; change it with `configure`.
      # @rbs return: EncodedId::Rails::Configuration
      def configuration
        @configuration ||= Configuration.new.freeze
      end

      # Yields a copy of the current configuration, validates it, then freezes it and makes it current.
      # @rbs () -> EncodedId::Rails::Configuration
      #    | () { (EncodedId::Rails::Configuration) -> void } -> EncodedId::Rails::Configuration
      def configure
        return configuration unless block_given?
        new_configuration = configuration.dup
        yield new_configuration
        new_configuration.validate!
        @configuration = new_configuration.freeze
      end
    end
  end
end
