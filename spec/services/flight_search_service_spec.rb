require 'rails_helper'

RSpec.describe FlightSearchService do
  before(:all) do
    @economy_class = SeatClass.create!(name: "Economy")

    @source_airport = Airport.create!(city: "Hyderabad", code: "HYD")
    @destination_airport = Airport.create!(city: "Delhi", code: "DEL")

    @flight = Flight.create!(
      flight_number: "AI123",
      source: @source_airport,
      destination: @destination_airport,
      departure_datetime: 2.days.from_now.change(hour: 10),
      arrival_datetime: 2.days.from_now.change(hour: 12),
      total_seats: 100,
      price: 3000
    )

    @flight_seat = FlightSeat.create!(
      flight: @flight,
      seat_class: @economy_class,
      total_seats: 100,
      available_seats: 20
    )

    @class_pricing = ClassPricing.create!(
      flight: @flight,
      seat_class: @economy_class,
      multiplier: 1
    )
  end

  after(:all) do
    ClassPricing.destroy_all
    FlightSeat.destroy_all
    Flight.destroy_all
    Airport.destroy_all
    SeatClass.destroy_all
  end

  describe "#search_flights" do
    context "when all inputs are valid" do
      it "returns available flights" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 2.days.from_now, "Economy", 2)
        result = service.search_flights
        expect(result[:status]).to eq(200)
        expect(result[:flights]).not_to be_empty
        expect(result[:flights][0][:flight_number]).to eq("AI123")
        expect(result[:message]).to eq("Flights found")
      end
    end

    context "when invalid class type is provided" do
      it "returns error with 400" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 2.days.from_now, "Luxury", 2)
        result = service.search_flights

        expect(result[:status]).to eq(400)
        expect(result[:message]).to eq("Invalid class type")
      end
    end

    context "when source or destination city is not served" do
      it "returns error with 400" do
        service = FlightSearchService.new("UnknownCity", "Delhi", 2.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(400)
        expect(result[:message]).to eq("We are not serving this source and destination.")
      end
    end

    context "when there are no flights between source and destination" do
      it "returns 404 error" do
        other_airport = Airport.create!(city: "Mumbai", code: "BOM")
        service = FlightSearchService.new("Mumbai", "Delhi", 2.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(404)
        expect(result[:message]).to eq("There are no flights operated from this source to destination.")

        other_airport.destroy
      end
    end

    context "when there are no flights on the selected date" do
      it "returns 404 error" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 5.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(404)
        expect(result[:message]).to include("No flights available on")
      end
    end

    context "when requesting more passengers than available seats" do
      it "returns 409 error" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 2.days.from_now, "Economy", 25)
        result = service.search_flights

        expect(result[:status]).to eq(409)
        expect(result[:message]).to include("fully booked")
      end
    end
  end
end
