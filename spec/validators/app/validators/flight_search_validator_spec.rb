require "rails_helper"

RSpec.describe FlightSearchValidator do
  describe "#valid?" do
    context "when all required fields are present and valid" do
      let(:params) do
        {
          source: "Bangalore",
          destination: "Hyderabad",
          date: "2025-07-14",
          passengers: 3,
          class_type: "business"
        }
      end

      it "returns true with no errors" do
        validator = described_class.new(params)
        expect(validator.valid?).to be true
        expect(validator.errors).to be_empty
      end

      it "returns correct passengers and class_type" do
        validator = described_class.new(params)
        validator.valid?

        expect(validator.passengers).to eq(3)
        expect(validator.class_type).to eq("business")
      end
    end

    context "when required fields are missing" do
      let(:params) { {} }

      it "returns false and adds all missing field errors" do
        validator = described_class.new(params)
        expect(validator.valid?).to be false

        expect(validator.errors).to include(
          "Source is missing",
          "Destination is missing",
          "Date is missing"
        )
      end

      it "defaults passengers to 1 and class_type to economy" do
        validator = described_class.new(params)
        validator.valid?

        expect(validator.passengers).to eq(1)
        expect(validator.class_type).to eq("economy")
      end
    end

    context "when source and destination are the same (case-insensitive)" do
      let(:params) do
        {
          source: "Chennai",
          destination: "chennai",
          date: "2025-07-14"
        }
      end

      it "returns false with appropriate error" do
        validator = described_class.new(params)
        expect(validator.valid?).to be false
        expect(validator.errors).to include("Source and Destination must be different")
      end
    end
  end
end
