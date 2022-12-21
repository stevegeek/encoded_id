# frozen_string_literal: true

require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/coder"
require_relative "rails/slugged_id"
require_relative "rails/slugged_id_parser"
require_relative "rails/salt"
require_relative "rails/encoder_methods"
require_relative "rails/query_methods"
require_relative "rails/finder_methods"
require_relative "rails/with_encoded_id"

module EncodedId
  module Rails
    # Configuration
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration) if block_given?
        configuration
      end
    end
  end

  # Expose directly on EncodedId
  Model = Rails::Model
  PathParam = Rails::PathParam
  SluggedPathParam = Rails::SluggedPathParam
end
