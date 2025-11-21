# frozen_string_literal: true

# rbs_inline: enabled

# Extension of MySqids (vendored Sqids) that adds blocklist mode support.
# This subclass overrides blocklist checking to support different modes
# without modifying the vendored library.
# In the future, the base class can be changed from MySqids to ::Sqids::Sqids
# once we use the official gem.
class SqidsWithBlocklistMode < MySqids
  # @rbs @blocklist_mode: Symbol
  # @rbs @blocklist_max_length: Integer

  # @rbs (?Hash[Symbol, untyped] options) -> void
  def initialize(options = {})
    @blocklist_mode = options[:blocklist_mode] || :length_threshold
    @blocklist_max_length = options[:blocklist_max_length] || 32

    # Remove our custom options before passing to parent
    parent_options = options.dup
    parent_options.delete(:blocklist_mode)
    parent_options.delete(:blocklist_max_length)

    super(parent_options)
  end

  private

  # Override blocked_id? to implement blocklist mode logic
  # @rbs (String id) -> bool
  def blocked_id?(id)
    return false unless check_blocklist?(id)

    super
  end

  # Determines if blocklist checking should be performed based on mode and ID length
  # @rbs (String id) -> bool
  def check_blocklist?(id)
    return false if @blocklist.empty?

    case @blocklist_mode
    when :always
      true
    when :length_threshold
      id.length <= @blocklist_max_length
    else
      # If :raise_if_likely mode it raises at configuration time, so if we get here, we check
      true
    end
  end
end
