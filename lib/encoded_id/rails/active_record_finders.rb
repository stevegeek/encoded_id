# frozen_string_literal: true

module EncodedId
  module Rails
    # This module overrides standard ActiveRecord finder methods to automatically decode encoded IDs.
    # Important: This module should NOT be used with models that use string-based primary keys (e.g., UUIDs)
    # as it will cause conflicts between string IDs and encoded IDs.
    module ActiveRecordFinders
      extend ActiveSupport::Concern

      included do
        if columns_hash["id"]&.type == :string
          ::Rails.logger.warn("EncodedId::Rails::ActiveRecordFinders has been included in #{name}, but this model uses string-based IDs. This may cause conflicts with encoded ID handling.")
        end
      end

      module ClassMethods
        def find(*args)
          return super unless args.size == 1 && args.first.is_a?(String)

          decoded_ids = decode_encoded_id(args.first)

          if decoded_ids.blank?
            raise ::ActiveRecord::RecordNotFound
          elsif decoded_ids.size == 1
            super(decoded_ids.first)
          else
            super(decoded_ids)
          end
        end

        # Override find_by_id to handle encoded IDs
        def find_by_id(id)
          if id.is_a?(String)
            decoded_ids = decode_encoded_id(id)
            return nil if decoded_ids.blank?
            return super(decoded_ids.first)
          end
          super
        end
      end
    end
  end
end
