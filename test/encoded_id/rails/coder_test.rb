# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::CoderTest < Minitest::Test
  def configuration
    EncodedId::Rails::Configuration.new
  end

  def resolve(options = {})
    EncodedId::Rails::Coder::Settings.resolve(configuration: configuration, options: options) { "the-model-salt" }
  end

  def test_settings_default_to_the_configuration
    settings = resolve

    assert_equal "the-model-salt", settings.salt
    assert_equal 8, settings.id_length
    assert_equal 128, settings.max_length
    assert_equal 4, settings.character_group_size
    assert_equal "-", settings.separator
    assert_equal :sqids, settings.encoder
    assert_equal false, settings.downcase_on_decode
  end

  def test_options_take_precedence_over_the_configuration
    settings = resolve(salt: "an-option-salt", id_length: 12, encoder: :hashids, blocklist_mode: :always)

    assert_equal "an-option-salt", settings.salt
    assert_equal 12, settings.id_length
    assert_equal :hashids, settings.encoder
    assert_equal :always, settings.blocklist_mode
  end

  def test_options_can_set_nil_and_false_explicitly
    configuration = EncodedId::Rails::Configuration.new
    configuration.downcase_on_decode = true
    settings = EncodedId::Rails::Coder::Settings.resolve(
      configuration: configuration,
      options: {max_length: nil, character_group_size: nil, separator: nil, downcase_on_decode: false}
    ) { "the-model-salt" }

    assert_nil settings.max_length
    assert_nil settings.character_group_size
    assert_nil settings.separator
    assert_equal false, settings.downcase_on_decode
  end

  def test_salt_block_is_not_called_when_options_give_a_salt
    settings = EncodedId::Rails::Coder::Settings.resolve(configuration: configuration, options: {salt: "an-option-salt"}) do
      raise "salt block called"
    end

    assert_equal "an-option-salt", settings.salt
  end

  def test_settings_are_frozen
    assert_predicate resolve, :frozen?
  end

  def test_coder_exposes_its_settings_and_round_trips
    settings = resolve
    coder = EncodedId::Rails::Coder.new(settings)

    assert_same settings, coder.settings
    assert_equal [42], coder.decode(coder.encode(42))
  end

  def test_coder_builds_its_reversible_id_once
    coder = EncodedId::Rails::Coder.new(resolve)
    calls = 0
    EncodedId::ReversibleId.define_singleton_method(:new) do |*args, **kwargs, &block|
      calls += 1
      super(*args, **kwargs, &block)
    end

    coder.decode(coder.encode(1))
    coder.encode(2)

    assert_equal 0, calls
  ensure
    EncodedId::ReversibleId.singleton_class.remove_method(:new)
  end

  def test_hashids_coder_requires_a_salt
    settings = EncodedId::Rails::Coder::Settings.resolve(configuration: configuration, options: {encoder: :hashids}) { nil }

    assert_raises(ArgumentError) { EncodedId::Rails::Coder.new(settings) }
  end
end
