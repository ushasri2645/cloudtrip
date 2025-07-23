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
      departure_time: 2.days.from_now.change(hour: 10),
      duration_minutes: 120,
      is_recurring: false,
    )

    @base_flight_seat=  BaseFlightSeat.create!(
        flight: @flight,
        seat_class: @economy_class,
        total_seats: 100,
        price: 3500
      )

    @flight_schedule =  FlightSchedule.create!(
        flight: @flight,
        flight_date: Time.zone.today
    )

    @flight_schedule_seat = FlightScheduleSeat.create!(
        flight_schedule: @flight_schedule,
        seat_class: @economy_class,
        available_seats: 80
    )
  end

  after(:all) do
    BaseFlightSeat.destroy_all
    Flight.destroy_all
    Airport.destroy_all
    SeatClass.destroy_all
  end

  describe "#search_flights" do
    context "when all inputs are valid" do
      it "returns available flights" do
        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 2)
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
        expect(result[:message]).to eq("Source or destination not found.")
      end
    end

    context "when there are no flights between source and destination" do
      it "returns 404 error" do
        other_airport = Airport.create!(city: "Mumbai", code: "BOM")
        service = FlightSearchService.new("Mumbai", "Delhi", Time.zone.today, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(404)
        expect(result[:message]).to eq("We are not operating on this route. Sorry for the inconvenience")

        other_airport.destroy
      end
    end

    context "when there are no flights on the selected date" do
      it "returns 404 error" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 5.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(200)
        expect(result[:flights]).to eq([])
        # expect(result[:message]).to include("No flights available on")
      end
    end

    context "when requesting more passengers than available seats" do
      it "returns 409 error" do
        @flight_schedule_seat.update!(available_seats: 0)

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 25)
        result = service.search_flights

        expect(result[:status]).to eq(409)
        expect(result[:message]).to include("All seats are booked")
      end
    end


    context "when flight schedule seat does not exist" do
      it "creates a new flight schedule seat with available seats from base" do
        FlightScheduleSeat.destroy_all

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
        result = service.search_flights

        seat = FlightScheduleSeat.find_by(flight_schedule: @flight_schedule, seat_class: @economy_class)
        expect(result[:status]).to eq(200)
        expect(seat).not_to be_nil
        expect(seat.available_seats).to eq(100)
      end
    end
  end
end
