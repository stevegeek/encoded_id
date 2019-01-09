# frozen_string_literal: true

module Core
  module WithUid
    extend ActiveSupport::Concern

    module ClassMethods
      def find_by_uid(uid)
        find_by(id: Core::ReversableId.decode(uid))
      end
    end

    def uid
      return unless id
      Core::ReversableId.encode(id)
    end
  end
end
