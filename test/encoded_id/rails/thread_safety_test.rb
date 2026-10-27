# frozen_string_literal: true

require "test_helper"

class EncodedId::Rails::ThreadSafetyTest < Minitest::Test
  THREAD_COUNT = 8
  IDS = ((1..150).to_a + [2**31 - 1, 2**40, 2**53 + 1]).freeze

  def setup
    @original_config = EncodedId::Rails.configuration
  end

  def teardown
    EncodedId::Rails.instance_variable_set(:@configuration, @original_config)
  end

  def test_model_encodes_and_decodes_from_many_threads_with_sqids
    use_encoder(:sqids)
    assert_model_consistent_across_threads
  end

  def test_model_encodes_and_decodes_from_many_threads_with_hashids
    use_encoder(:hashids)
    assert_model_consistent_across_threads
  end

  def test_shared_coder_gives_single_threaded_results
    [:sqids, :hashids].each do |encoder|
      coder = MyModel.encoded_id_coder(encoder: encoder)
      expected = IDS.to_h do |id|
        encoded = coder.encode(id)
        [id, [encoded, coder.decode(encoded)]]
      end

      expected.each { |id, (_encoded, decoded)| assert_equal [id], decoded }

      mismatches = Queue.new
      run_in_threads do |index|
        expected.keys.shuffle(random: Random.new(index)).each do |id|
          encoded, decoded = expected[id]
          actual_encoded = coder.encode(id)
          actual_decoded = coder.decode(encoded)
          mismatches << [encoder, :encode, id, encoded, actual_encoded] unless actual_encoded == encoded
          mismatches << [encoder, :decode, encoded, decoded, actual_decoded] unless actual_decoded == decoded
        end
      end

      assert_empty Array.new(mismatches.size) { mismatches.pop }
    end
  end

  private

  def use_encoder(encoder)
    config = @original_config.dup
    config.encoder = encoder
    EncodedId::Rails.instance_variable_set(:@configuration, config)
  end

  def model_results(id)
    record = MyModel.new(id: id)
    encoded_id = record.encoded_id
    [record.encoded_id_hash, encoded_id, MyModel.decode_encoded_id(encoded_id)]
  end

  def assert_model_consistent_across_threads
    expected = IDS.to_h { |id| [id, model_results(id)] }
    expected.each { |id, (_hash, _encoded_id, decoded)| assert_equal [id], decoded }

    mismatches = Queue.new
    run_in_threads do |index|
      expected.keys.shuffle(random: Random.new(index)).each do |id|
        actual = model_results(id)
        mismatches << [id, expected[id], actual] unless actual == expected[id]
      end
    end

    assert_empty Array.new(mismatches.size) { mismatches.pop }
  end

  def run_in_threads
    start = Queue.new
    threads = Array.new(THREAD_COUNT) do |index|
      Thread.new do
        Thread.current.report_on_exception = false
        start.pop
        yield index
      end
    end
    THREAD_COUNT.times { start << true }
    threads.map(&:value)
  end
end
