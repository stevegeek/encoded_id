# frozen_string_literal: true

require_relative "rails/configuration"
require_relative "rails/coder"
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
end
