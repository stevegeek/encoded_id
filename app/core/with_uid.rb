# frozen_string_literal: true

module Core
  module WithUid
    extend ActiveSupport::Concern

    class_methods do
      # Find by UID and optionally ensure record ID is the same as constraint (can be slugged)
      def find_by_uid(slugged_uid, with_id: nil)
        uid = extract_id_part(slugged_uid)
        find_via_custom_id(decode_uid(uid), :id, compare_to: with_id)
      end

      def find_by_uid!(slugged_uid, with_id: nil)
        uid = extract_id_part(slugged_uid)
        find_via_custom_id!(decode_uid(uid), :id, compare_to: with_id)
      end

      # Find by a fixed slug value (assumed as an attribute value in the DB)
      def find_by_fixed_slug(slug, attribute: :slug, with_id: nil)
        find_via_custom_id(slug, attribute, compare_to: with_id)
      end

      def find_by_fixed_slug!(slug, attribute: :slug, with_id: nil)
        find_via_custom_id!(slug, attribute, compare_to: with_id)
      end

      # Find by record ID where the ID has been slugged
      def find_by_slugged_id(slugged_id, with_id: nil)
        id_part = decode_slugged_ids(slugged_id)
        unless with_id.nil?
          return unless with_id == id_part
        end
        where(id: id_part)&.first
      end

      def find_by_slugged_id!(slugged_id, with_id: nil)
        id_part = decode_slugged_ids(slugged_id)
        unless with_id.nil?
          raise ActiveRecord::RecordNotFound unless with_id == id_part
        end
        find(id_part)
      end

      # relation helpers

      def where_uid(slugged_uid)
        where(id: decode_uid(extract_id_part(slugged_uid)))
      end

      def where_fixed_slug(slug, attribute: :slug)
        where(attribute => slug)
      end

      def where_slugged_id(slugged_id)
        id_part = decode_slugged_ids(slugged_id)
        where(id: id_part)
      end

      # Encode helpers

      def encode_uid(id, options = {})
        raise(StandardError, "You must pass an ID") if id.blank?
        salt = uid_salt
        raise(StandardError, "Model salt is invalid") if salt.blank? || salt.size < 4
        Core::ReversableId.new(**options.merge(salt: salt)).encode(id)
      end

      def encode_multi_uid(uids, options = {})
        raise(StandardError, "You must pass IDs") if uids.blank?
        salt = uid_salt
        raise(StandardError, "Model salt is invalid") if salt.blank? || salt.size < 4
        Core::ReversableId.new(**options.merge(salt: salt)).encode(*uids)
      end

      # Decode helpers

      # Decode a UID (can be slugged)
      def decode_uid(slugged_uid, options = {})
        internal_decode_uid(slugged_uid, options)&.first
      end

      def decode_multi_uid(slugged_uid, options = {})
        internal_decode_uid(slugged_uid, options)
      end

      # Decode a Slugged ID
      def decode_slugged_id(slugged)
        return if slugged.blank?
        extract_id_part(slugged).to_i
      end

      # Decode a set of slugged IDs
      def decode_slugged_ids(slugged)
        return if slugged.blank?
        extract_id_part(slugged).split("-").map(&:to_i)
      end

      # This must be implemented for the class with this mixin
      def uid_salt
        raise NotImplementedError, "You must implement uid_salt for each model with UIDs. Return a salt string"
      end
    end

    # Instance methods

    def uid(options = {})
      self.class.encode_uid(id, options)
    end

    # (slug)--(hash id)
    def slugged_uid(with: :slug)
      @slugged_uid ||= generate_composite_id(with, :uid, split_at: nil)
    end

    # (name slug)--(record id(s) (separated by hyphen))
    def slugged_id(with: :slug)
      @slugged_id ||= generate_composite_id(with, :id)
    end

    # By default slug calls `name` if it exists or returns class name
    def slug
      klass = self.class.name.underscore
      return klass unless respond_to? :name
      given_name = name
      return given_name if given_name.present?
      klass
    end

    # Private class methods

    included do
      class << self
        private

        def internal_decode_uid(slugged_uid, options)
          return if slugged_uid.blank?
          uid = extract_id_part(slugged_uid)
          return if uid.blank?
          Core::ReversableId.new(**options.merge(salt: uid_salt)).decode(uid)
        end

        def find_via_custom_id(value, attribute, compare_to: nil)
          return if value.blank?
          record = find_by(Hash[attribute, value])
          return unless record
          unless compare_to.nil?
            return unless compare_to == record.send(attribute)
          end
          record
        end

        def find_via_custom_id!(value, attribute, compare_to: nil)
          raise ActiveRecord::RecordNotFound if value.blank?
          record = find_by!(Hash[attribute, value])
          unless compare_to.nil?
            raise ActiveRecord::RecordNotFound unless compare_to == record.send(attribute)
          end
          record
        end

        def extract_id_part(slugged_id)
          return if slugged_id.blank?
          has_slug = slugged_id.include?("--")
          return slugged_id unless has_slug
          split_slug = slugged_id.split("--")
          split_slug.last if has_slug && split_slug.size > 1
        end
      end
    end

    private

    def generate_composite_id(name_method, id_method, id_method_options = nil)
      name_part = send(name_method)
      id_part = id_method_options ? send(id_method, id_method_options) : send(id_method)
      unless id_part.present? && name_part.present?
        raise(StandardError, "The model has no #{id_method} or #{name_method}")
      end
      "#{name_part.to_s.parameterize}--#{id_part}"
    end
  end
end
