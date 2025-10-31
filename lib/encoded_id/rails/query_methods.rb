# frozen_string_literal: true

# rbs_inline: enabled

module EncodedId
  module Rails
    module QueryMethods
      # Methods provided by other mixins/ActiveRecord
      # @rbs!
      #   def decode_encoded_id: (String) -> Array[Integer]?
      #   def where: (**untyped) -> untyped

      # @rbs (*String slugged_encoded_ids) -> untyped
      def where_encoded_id(*slugged_encoded_ids)
        slugged_encoded_ids = slugged_encoded_ids.flatten

        raise ::ActiveRecord::RecordNotFound if slugged_encoded_ids.empty?

        decoded_ids = slugged_encoded_ids.flat_map do |slugged_encoded_id|
          decode_encoded_id(slugged_encoded_id).tap do |decoded_id|
            raise ::ActiveRecord::RecordNotFound if decoded_id.nil?
          end
        end

        where(id: decoded_ids)
      end
    end
  end
end
