# frozen_string_literal: true

module Core
  module WithUid
    extend ActiveSupport::Concern

    class_methods do
      # Find by UID and optionally ensure record ID is the same as constraint
      def find_by_uid(uid, with_id: nil)
        find_via_custom_id(Core::ReversableId.decode(uid), :id, compare_to: with_id)
      end

      def find_by_uid!(uid, with_id: nil)
        find_via_custom_id!(Core::ReversableId.decode(uid), :id, compare_to: with_id)
      end

      def find_by_fixed_slug(slug, attribute: :slug, with_id: nil)
        find_via_custom_id(slug, attribute, compare_to: with_id)
      end

      def find_by_fixed_slug!(slug, attribute: :slug, with_id: nil)
        find_via_custom_id!(slug, attribute, compare_to: with_id)
      end

      def find_by_slugged_uid(slugged_uid, with_id: nil)
        uid = get_id_from_slugged(slugged_uid)
        find_by_uid(uid, with_id: with_id)
      end

      def find_by_slugged_uid!(slugged_uid, with_id: nil)
        uid = get_id_from_slugged(slugged_uid)
        find_by_uid!(uid, with_id: with_id)
      end

      def find_by_slugged_id(slugged_id, with_id: nil)
        id_part = get_ids_from_slugged(slugged_id)
        unless with_id.nil?
          return unless with_id == id_part
        end
        find(id_part)
      end

      def find_by_slugged_id!(slugged_id, with_id: nil)
        id_part = get_ids_from_slugged(slugged_id)
        unless with_id.nil?
          raise ActiveRecord::RecordNotFound unless with_id == id_part
        end
        find!(id_part)
      end
    end

    # Instance methods

    def uid
      raise(StandardError, "The model has no ID") unless id
      Core::ReversableId.encode(id)
    end

    # (slug)--(hash id)
    def slugged_uid(with: :name)
      generate_composite_id(with, :uid)
    end

    # (name slug)-(record id)
    def slugged_id(with: :name)
      generate_composite_id(with, :id)
    end

    # Private class methods

    included do
      class << self
        private

        def get_id_from_slugged(slugged)
          slugged.split("--").last
        end

        def get_ids_from_slugged(slugged)
          get_id_from_slugged(slugged).split("-")
        end

        def find_via_custom_id(value, attribute, compare_to: nil)
          record = find_by(Hash[attribute, value])
          return unless record
          unless compare_to.nil?
            return unless compare_to == record.send(attribute)
          end
          record
        end

        def find_via_custom_id!(value, attribute, compare_to: nil)
          record = find_by!(Hash[attribute, value])
          unless compare_to.nil?
            raise ActiveRecord::RecordNotFound unless compare_to == record.send(attribute)
          end
          record
        end
      end
    end

    private

    def generate_composite_id(name_method, id_method)
      name_part = send(name_method)
      id_part = send(id_method)
      unless id_part.present? && name_part.present?
        raise(StandardError, "The model has no #{id_method} or #{name_method}")
      end
      "#{name_part.to_s.parameterize}--#{id_part}"
    end
  end
end
