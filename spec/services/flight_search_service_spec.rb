require 'rails_helper'

RSpec.describe FlightSearchService, type: :service do
  let!(:economy_class) { SeatClass.create!(name: "Economy") }
  let!(:source_airport) { Airport.create!(city: "Hyderabad", code: "HYD") }
  let!(:destination_airport) { Airport.create!(city: "Delhi", code: "DEL") }
  let!(:flight) do
    Flight.create!(
      flight_number: "AI123",
      source: source_airport,
      destination: destination_airport,
      departure_time: Time.zone.now.change(hour: 10),
      duration_minutes: 120,
      is_recurring: false
    )
  end
  let!(:base_seat) do
    BaseFlightSeat.create!(
      flight: flight,
      seat_class: economy_class,
      total_seats: 100,
      price: 3000
    )
  end
  let!(:flight_schedule) do
    FlightSchedule.create!(
      flight: flight,
      flight_date: Time.zone.today
    )
  end
  let!(:flight_schedule_seat) do
    FlightScheduleSeat.create!(
      flight_schedule: flight_schedule,
      seat_class: economy_class,
      available_seats: 90
    )
  end

  ValidatorStub = Struct.new(:source, :destination, :parsed_date, :class_type, :passengers)

  def build_validator(source: "Hyderabad", destination: "Delhi", date: Time.zone.today.to_s, class_type: "Economy", passengers: 2)
    ValidatorStub.new(
      source.downcase,
      destination.downcase,
      Date.parse(date),
      class_type.downcase,
      passengers
    )
  end

  describe "#search" do
    context "with valid data" do
      it "returns flight data" do
        service = FlightSearchService.new(build_validator)
        result = service.search
        expect(result).to be_an(Array)
        expect(result.first[:flight_number]).to eq("AI123")
      end
    end

    context "with invalid class_type" do
      it "returns :invalid_class_type" do
        v = build_validator(class_type: "invalid_class")
        service = FlightSearchService.new(v)
        expect(service.search).to eq(:invalid_class_type)
      end
    end

    context "when source or destination doesn't exist" do
      it "returns :invalid_airports" do
        v = build_validator(source: "Unknown")
        service = FlightSearchService.new(v)
        expect(service.search).to eq(:invalid_airports)
      end
    end

    context "when no flights exist on date" do
      it "returns :no_flights_on_date" do
        flight_schedule.destroy
        v = build_validator(date: (Time.zone.today + 3).to_s)
        service = FlightSearchService.new(v)
        expect(service.search).to eq(:no_flights_on_date)
      end
    end

    context "when no route exists" do
      it "returns :route_not_operated" do
        flight.destroy
        v = build_validator
        service = FlightSearchService.new(v)
        expect(service.search).to eq(:route_not_operated)
      end
    end

    context "when no seats for class" do
      it "returns :no_class_available" do
        base_seat.destroy
        flight_schedule_seat.destroy
        service = FlightSearchService.new(build_validator)
        expect(service.search).to eq(:no_class_available)
      end
    end

    context "when seats are all booked" do
      it "returns :all_seats_booked" do
        flight_schedule_seat.update(available_seats: 0)
        service = FlightSearchService.new(build_validator)
        expect(service.search).to eq(:all_seats_booked)
      end
    end
    it "returns 'One-time flight' when there is no recurrence" do
      service = FlightSearchService.new(build_validator)
      result = service.search

      expect(result.first[:recurrence_days]).to eq("One-time flight")
    end
  end
end
