# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::ReversableId do
  describe ".encodes" do
    subject { described_class.encode(id) }

    let(:id) { 123 }

    it { is_expected.to be_instance_of String }

    it { is_expected.to eql "p5w9-z27j" }

    context "with ID is a string" do
      let(:id) { "123" }

      it { is_expected.to be_instance_of String }

      it { is_expected.to eql "p5w9-z27j" }
    end

    context "with ID is a string and compact enabled" do
      subject { described_class.new(split_at: nil).encode(id) }

      let(:id) { "123" }

      it { is_expected.to be_instance_of String }

      it { is_expected.to eql "p5w9z27j" }
    end

    context "when output doesnt contain invalid chars" do
      it { is_expected.not_to include "l" }
      it { is_expected.not_to include "i" }
      it { is_expected.not_to include "o" }
    end

    context "when encode multiple numbers" do
      subject { described_class.encode(78, 45) }

      it { is_expected.to eql "7aq6-0zqw" }
    end

    context "when encoding values which cannot be encoded to desired length it grows" do
      subject { described_class.encode(78, 45, 32) }

      it { is_expected.to eql "9n80-qbf8-a" }
    end
  end

  describe ".decodes" do
    subject(:decoded) { described_class.decode(uid_str) }

    let(:uid_str) { "p5w9-z27j" }

    it { is_expected.to be_instance_of Array }

    it { is_expected.to eql [123] }

    context "when decode multiple numbers" do
      let(:uid_str) { "7aq6-0zqw" }

      it { is_expected.to eql [78, 45] }
    end

    context "when decode multiple numbers over length" do
      let(:uid_str) { "9n80-qbf8-a" }

      it { is_expected.to eql [78, 45, 32] }
    end

    context "when characters are mapped" do
      describe "output contains mapped chars, o" do
        let(:uid_str) { "7aq6-ozqw" }

        it { is_expected.to eql [78, 45] }
      end

      describe "output contains mapped chars, i" do
        let(:uid_str) { "p5w9-z27i" }

        it { is_expected.to eql [123] }
      end
    end

    context "when hash encodes nothing and output contains invalid chars but hash format is valid" do
      let(:uid_str) { "ozgf-w$65" }

      it { is_expected.to eql [] }
    end

    context "when hash format is broken" do
      let(:uid_str) { "ogf-w$5^5" }

      it "raises" do
        expect { decoded }.to raise_error Hashids::InputError
      end
    end
  end
end
