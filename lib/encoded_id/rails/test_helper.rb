# frozen_string_literal: true

# rbs_inline: enabled

require "encoded_id/rails"

module EncodedId
  module Rails
    # Include in a test case to run code with a changed configuration:
    #
    #   require "encoded_id/rails/test_helper"
    #
    #   class UserTest < ActiveSupport::TestCase
    #     include EncodedId::Rails::TestHelper
    #   end
    module TestHelper
      # Runs the block with the configuration changed by the overrides, then restores the previous one,
      # even if the block raises. Returns the block's value.
      # It swaps the configuration for the whole process, so tests using it must not run in parallel threads.
      # @rbs [T] (**untyped overrides) { () -> T } -> T
      def with_encoded_id_configuration(**overrides)
        previous = EncodedId::Rails.configuration
        EncodedId::Rails.configure { |config| overrides.each { |name, value| config.public_send(:"#{name}=", value) } }
        yield
      ensure
        EncodedId::Rails.instance_variable_set(:@configuration, previous)
      end
    end
  end
end
