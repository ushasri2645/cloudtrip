require 'rails_helper'

RSpec.describe FlightBookingValidator do
  let(:valid_params) do
    {
      flight_number: "AI101",
      source: "Chennai",
      destination: "Delhi",
      date: "2025-08-01",
      class_type: "economy",
      passengers: 2
    }
  end

  describe "#valid?" do
    context "with all valid parameters" do
      it "returns true and no errors" do
        validator = FlightBookingValidator.new(valid_params)
        expect(validator.valid?).to be true
        expect(validator.errors).to be_empty
      end
    end

    context "when required fields are missing" do
      it "returns false and includes error message" do
        params = valid_params.except(:flight_number, :source)
        validator = FlightBookingValidator.new(params)

        expect(validator.valid?).to be false
        expect(validator.errors).to include(
          a_hash_including(
            message: a_string_matching(/Missing required fields: flight_number, source/),
            status: 400
          )
        )
      end
    end

    context "when passenger count is missing" do
      it "returns false with error for passenger count" do
        params = valid_params.merge(passengers: 0)
        validator = FlightBookingValidator.new(params)

        expect(validator.valid?).to be false
        expect(validator.errors).to include(
          a_hash_including(
            message: "Passenger count must be at least 1",
            status: 400
          )
        )
      end
    end

    context "when all fields are missing" do
      it "returns false and shows all missing field errors" do
        validator = FlightBookingValidator.new({})

        expect(validator.valid?).to be false
        expect(validator.errors).to include(
          a_hash_including(
            message: a_string_matching(/Missing required fields: flight_number, source, destination, date, class_type, passengers/),
            status: 400
          )
        )
      end
    end
  end

  describe "attribute readers" do
    let(:validator) { FlightBookingValidator.new(valid_params) }

    it "returns correct attributes" do
      expect(validator.flight_number).to eq("AI101")
      expect(validator.source).to eq("Chennai")
      expect(validator.destination).to eq("Delhi")
      expect(validator.date).to eq("2025-08-01")
      expect(validator.class_type).to eq("economy")
      expect(validator.passengers).to eq(2)
    end
  end
end
