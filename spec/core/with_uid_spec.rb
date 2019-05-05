# frozen_string_literal: true

require "rails_helper"

RSpec.describe Core::WithUid do
  describe "boolean attributes" do
    class TestWithUidClassNoName
      include Core::TypedAttributesModel
      include Core::WithUid

      def self.uid_salt
        "lha83hk73y9r3jp9js98ugo84"
      end

      attr_string :id
      attr_string :title, default: "Beef Tenderloins/Prime"

      def self.find_by(_id); end

      def self.find_by!(_id); end

      def self.find(_id); end

      def self.find!(_id); end
    end

    class TestWithUidClass < TestWithUidClassNoName
      def name
        "My Favourite Shop!"
      end
    end

    subject(:test_instance) { TestWithUidClass.new(id: "123") }

    let(:test_record) { TestWithUidClass.new(id: "123", title: "Bar") }

    before do
      allow(TestWithUidClass).to receive(:find_by).with(id: [123]) { test_record }
      allow(TestWithUidClass).to receive(:find_by).with(id: [124]).and_return(nil)
      allow(TestWithUidClass).to receive(:find_by!).with(id: [123]) { test_record }
      allow(TestWithUidClass).to receive(:find_by!).with(id: [124]).and_raise(ActiveRecord::RecordNotFound)
    end

    describe "#uid" do
      it "generates a reversible ID" do
        expect(test_instance.uid).to eql "p5w9-z27j"
      end
    end

    describe "#slugged_uid" do
      context "with name method" do
        it "generates a slugged ID reversible with default attribute" do
          expect(test_instance.slugged_uid).to eql "my-favourite-shop--p5w9z27j"
        end

        it "generates a slugged ID reversible with specific attribute" do
          expect(test_instance.slugged_uid(with: :title)).to eql "beef-tenderloins-prime--p5w9z27j"
        end

        it "generates a slugged ID reversible with default slug name of class if name blank" do
          allow(test_instance).to receive(:name).and_return("")
          expect(test_instance.slugged_uid).to eql "test_with_uid_class--p5w9z27j"
        end
      end

      context "with no name method" do
        subject(:test_instance) { TestWithUidClassNoName.new(id: "123") }

        it "generates a slugged ID reversible with default slug name of class" do
          expect(test_instance.slugged_uid).to eql "test_with_uid_class_no_name--p5w9z27j"
        end
      end
    end

    describe "#slugged_id" do
      it "generates a slugged ID with default attribute" do
        expect(test_instance.slugged_id).to eql "my-favourite-shop--123"
      end

      it "generates a slugged ID with specific attribute" do
        expect(test_instance.slugged_id(with: :title)).to eql "beef-tenderloins-prime--123"
      end
    end

    describe ".decode_uid" do
      it "generates the original ID from the UID" do
        expect(TestWithUidClass.decode_uid("p5w9-z27j")).to eql [123]
      end
    end

    describe ".decode_slugged_uid" do
      it "generates the original ID from the slugged UID" do
        expect(TestWithUidClass.decode_slugged_uid("test_with_uid_class_no_name--p5w9z27j")).to eql [123]
      end
    end

    describe ".decode_slugged_id" do
      it "generates the original ID from the slugged ID" do
        expect(TestWithUidClass.decode_slugged_id("my-favourite-shop--123")).to eql [123]
      end
    end

    describe ".decode_slugged_ids" do
      it "generates the original IDs from the slugged IDs" do
        expect(TestWithUidClass.decode_slugged_ids("my-favourite-shop--123-456")).to eql [123, 456]
      end
    end

    describe ".find_by_uid" do
      it "returns the record" do
        expect(TestWithUidClass.find_by_uid("p5w9-z27j")).to eql test_record
      end

      it "returns the record if the constraint id is the same" do
        expect(TestWithUidClass.find_by_uid("p5w9-z27j", with_id: "123")).to eql test_record
      end

      it "returns nil if the constraint id is not the same" do
        expect(TestWithUidClass.find_by_uid("p5w9-z27j", with_id: "456")).to be nil
      end

      it "returns nil if the record does not exist" do
        expect(TestWithUidClass.find_by_uid("ke7p-6ayb")).to be nil
      end
    end

    describe ".find_by_uid!" do
      it "returns the record" do
        expect(TestWithUidClass.find_by_uid!("p5w9z27j")).to eql test_record
      end

      it "returns the record if the constraint id is the same" do
        expect(TestWithUidClass.find_by_uid!("p5w9z27j", with_id: "123")).to eql test_record
      end

      it "raises if the constraint id is not the same" do
        expect {
          TestWithUidClass.find_by_uid!("p5w9z27j", with_id: "456")
        }.to raise_error ActiveRecord::RecordNotFound
      end

      it "raises if the record does not exist" do
        expect {
          TestWithUidClass.find_by_uid!("ke7p-6ayb")
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with fixed DB slugs" do
      before do
        allow(TestWithUidClass).to receive(:find_by).with(slug: "slugA") { test_record }
        allow(TestWithUidClass).to receive(:find_by).with(slug: "slugB").and_return(nil)
        allow(TestWithUidClass).to receive(:find_by!).with(slug: "slugA") { test_record }
        allow(TestWithUidClass).to receive(:find_by!).with(slug: "slugB").and_raise(ActiveRecord::RecordNotFound)
      end

      describe ".find_by_fixed_slug" do
        it "returns the record" do
          expect(TestWithUidClass.find_by_fixed_slug("slugA")).to eql test_record
        end

        it "returns nil if the record does not exist" do
          expect(TestWithUidClass.find_by_fixed_slug("slugB")).to be nil
        end
      end

      describe ".find_by_fixed_slug!" do
        it "returns the record" do
          expect(TestWithUidClass.find_by_fixed_slug!("slugA")).to eql test_record
        end

        it "returns nil if the record does not exist" do
          expect {
            TestWithUidClass.find_by_fixed_slug!("slugB")
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    describe ".find_by_slugged_uid" do
      it "returns the record" do
        expect(TestWithUidClass.find_by_slugged_uid("slug--p5w9z27j")).to eql test_record
      end

      it "returns nil if the record does not exist" do
        expect(TestWithUidClass.find_by_slugged_uid("slug--ke7p-6ayb")).to be nil
      end
    end

    describe ".find_by_slugged_uid!" do
      it "returns the record" do
        expect(TestWithUidClass.find_by_slugged_uid!("slug--p5w9z27j")).to eql test_record
      end

      it "returns nil if the record does not exist" do
        expect {
          TestWithUidClass.find_by_slugged_uid!("slug--ke7p6ayb")
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "when finding by id" do
      before do
        allow(TestWithUidClass).to receive(:find).with([123]) { test_record }
        allow(TestWithUidClass).to receive(:find).with([123, 234]) { test_record }
        allow(TestWithUidClass).to receive(:find).with([456]).and_return(nil)
        allow(TestWithUidClass).to receive(:find!).with([123]) { test_record }
        allow(TestWithUidClass).to receive(:find!).with([456]).and_raise(ActiveRecord::RecordNotFound)
      end

      describe ".find_by_slugged_id" do
        it "returns the record" do
          expect(TestWithUidClass.find_by_slugged_id("slug--123")).to eql test_record
        end

        it "returns the records with multiple ids" do
          expect(TestWithUidClass.find_by_slugged_id("slug--123-234")).to eql test_record
        end

        it "returns nil if the record does not exist" do
          expect(TestWithUidClass.find_by_slugged_id("slug--456")).to be nil
        end
      end

      describe ".find_by_slugged_id!" do
        it "returns the record" do
          expect(TestWithUidClass.find_by_slugged_id!("slug--123")).to eql test_record
        end

        it "returns nil if the record does not exist" do
          expect {
            TestWithUidClass.find_by_slugged_id!("slug--456")
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
