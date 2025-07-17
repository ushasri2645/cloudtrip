
require "rails_helper"

RSpec.describe FlightSearchService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:source)       { "Bangalore" }
  let(:destination)  { "Hyderabad" }
  let(:class_type)   { "economy" }
  let(:passengers)   { 2 }
  let(:base_price)   { 1_000.0 }
  let(:dynamic_fee)  { 50.0 }
  let(:travel_date)  { "2025-07-15" }
  let(:frozen_now)   { Time.zone.parse("2025-07-14 12:00") }

  let(:flight_hash) do
    {
      source:            source,
      destination:       destination,
      departure_date:    travel_date,
      departure_time:    "08:00 AM",
      economy_seats:     10,
      economy_total:     20,
      business_seats:    5,
      business_total:    10,
      first_class_seats: 2,
      first_class_total: 2,
      price:             base_price
    }
  end

  before do
    travel_to(frozen_now)

    allow(FlightDataService).to receive(:read_flights).and_return([ flight_hash ])
    allow(DynamicPricingService).to receive(:calculate_price).and_return(dynamic_fee)
  end


  subject do
    described_class.new(source, destination, travel_date, class_type, passengers)
                   .search_flights
  end

  context "when a matching flight exists" do
    it "returns it with accurate fare calculations" do
      result = subject

      expect(result[:message]).to eq("Flights found")
      expect(result[:flights].size).to eq(1)

      flight = result[:flights].first
      expect(flight[:class_type]).to           eq(class_type)
      expect(flight[:price_per_seat]).to       eq(dynamic_fee.round(2))
      expect(flight[:price_per_person]).to     eq((dynamic_fee + base_price).round(2))
      expect(flight[:total_fare]).to           eq(((dynamic_fee + base_price) * passengers).round(2))
      expect(flight[:extra_price]).to          eq(dynamic_fee.round(2))
    end
  end

  context "when the flight has already departed today" do
    let(:travel_date) { frozen_now.to_date.to_s }
    let(:flight_hash) { super().merge(departure_time: "08:00 AM") }

    it "returns no matching flights" do
      result = subject
      expect(result[:flights]).to be_empty
      expect(result[:message]).to eq("No matching flights available")
    end
  end

  context "when not enough seats are available" do
    let(:passengers) { 12 }

    it "returns no matching flights" do
      result = subject
      expect(result[:flights]).to be_empty
    end
  end

 context "when source or destination do not match" do
  let(:destination) { "Mumbai" }
  let(:flight_hash) do
    super().merge(destination: "Hyderabad")
  end

    it "returns no matching flights" do
        result = subject
        expect(result[:flights]).to be_empty
        expect(result[:message]).to eq("No matching flights available")
    end
 end
end
