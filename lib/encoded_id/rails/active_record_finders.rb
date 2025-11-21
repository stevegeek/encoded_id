# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    # This module overrides standard ActiveRecord finder methods to automatically decode encoded IDs.
    # Important: This module should NOT be used with models that use string-based primary keys (e.g., UUIDs)
    # as it will cause conflicts between string IDs and encoded IDs.
    module ActiveRecordFinders
      extend ActiveSupport::Concern

      # @rbs!
      #   include ::ActiveRecord::FinderMethods
      #   extend ::ActiveRecord::QueryMethods

      included do
        if columns_hash["id"]&.type == :string
          ::Rails.logger.warn("EncodedId::Rails::ActiveRecordFinders has been included in #{name}, but this model uses string-based IDs. This may cause conflicts with encoded ID handling.")
        end

        unless columns_hash.key?("id")
          ::Rails.logger.warn("EncodedId::Rails::ActiveRecordFinders has been included in #{name}, but this model has no 'id' column. The finders will not work as expected.")
        end

        if primary_key && primary_key != "id" && columns_hash.key?("id")
          ::Rails.logger.warn("EncodedId::Rails::ActiveRecordFinders has been included in #{name}, but the primary key is '#{primary_key}', not 'id'. This may cause unexpected behavior with find methods.")
        end

        # Use prepend so our methods take precedence over ActiveRecord's dynamic finders
        singleton_class.prepend(ClassMethodsPrepend)
      end

      # Class methods for overriding ActiveRecord's finder methods to decode encoded IDs.
      module ClassMethodsPrepend
        # @rbs (*untyped args) -> untyped
        def find(*args)
          first_arg = args.first
          return super unless args.size == 1 && first_arg.is_a?(String)

          decoded_ids = decode_encoded_id(first_arg)

          if decoded_ids.blank?
            raise ::ActiveRecord::RecordNotFound
          elsif decoded_ids.size == 1
            super(decoded_ids.first)
          else
            super(decoded_ids)
          end
        end

        # Override find_by_id to handle encoded IDs
        # @rbs (untyped id) -> untyped
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
