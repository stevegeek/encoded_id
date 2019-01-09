# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::ReversableId do
  describe ".encodes" do
    subject { described_class.encode(id) }

    let(:id) { 123 }

    it { is_expected.to be_instance_of String }

    it { is_expected.to eql "qy3x-bn8v-4n8k-jgvr" }

    context "with ID is a string" do
      let(:id) { "123" }

      it { is_expected.to be_instance_of String }

      it { is_expected.to eql "qy3x-bn8v-4n8k-jgvr" }
    end

    context "when output doesnt contain invalid chars" do
      it { is_expected.not_to include "l" }
      it { is_expected.not_to include "i" }
      it { is_expected.not_to include "o" }
    end

    context "when encode multiple numbers" do
      subject { described_class.encode(78, 45, 56, 678) }

      it { is_expected.to eql "e5ya-n1bp-0zgf-wr65" }
    end
  end

  describe ".decodes" do
    subject(:decoded) { described_class.decode(uid_str) }

    let(:uid_str) { "qy3x-bn8v-4n8k-jgvr" }

    it { is_expected.to be_instance_of Array }

    it { is_expected.to eql [123] }

    context "when decode multiple numbers" do
      let(:uid_str) { "e5ya-n1bp-0zgf-wr65" }

      it { is_expected.to eql [78, 45, 56, 678] }
    end

    context "when output contains mapped chars" do
      let(:uid_str) { "e5ya-nlbp-ozgf-wr65" }

      it { is_expected.to eql [78, 45, 56, 678] }
    end

    context "when output contains invalid chars" do
      let(:uid_str) { "e5ya-nlbp-ozgf-w$65" }

      it "raises" do
        expect { decoded }.to raise_error Hashids::InputError
      end
    end
  end
end
