# frozen_string_literal: true

require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/with_encoded_id"

module EncodedId
  module Rails
    # Configuration
    class << self
      attr_reader :configuration

      def configure
        @configuration ||= Configuration.new
        yield(configuration) if block_given?
        configuration
      end
    end
  end

  # Expose directly on EncodedId
  WithEncodedId = Rails::WithEncodedId
end
