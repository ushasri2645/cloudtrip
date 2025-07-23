require 'rails_helper'

RSpec.describe FlightBookingService, type: :service do
    before(:all) do
    # Delete everything to start fresh

    FlightScheduleSeat.delete_all
    FlightSchedule.delete_all
    BaseFlightSeat.delete_all
    SeatClass.delete_all
    Flight.delete_all
    Airport.delete_all
  end

  after(:all) do
    # Clean up after tests to leave DB clean
    FlightScheduleSeat.delete_all
    FlightSchedule.delete_all
     BaseFlightSeat.delete_all
    SeatClass.delete_all
    Flight.delete_all
    Airport.delete_all
  end
  let!(:source_airport) { Airport.create!(city: "Delhi", code: "DELt") }
  let!(:destination_airport) { Airport.create!(city: "Mumbai", code: "BOM") }

  let!(:flight) do
    Flight.create!(
      flight_number: "AI101",
      source: source_airport,
      destination: destination_airport,
      departure_time: (Time.zone.now).strftime("%H:%M:%S"),
      duration_minutes: 120
    )
  end

  let!(:seat_class) { SeatClass.create!(name: "Economy") }

  let!(:base_flight_seat) do
      BaseFlightSeat.create!(
        flight: flight,
        seat_class: seat_class,
        total_seats: 100,
        price: 3500
      )
    end
  let!(:flight_schedule) do
    FlightSchedule.create!(
      flight: flight,
      flight_date: Date.today
    )
  end

  let!(:schedule_seat) do
    FlightScheduleSeat.create!(
      flight_schedule: flight_schedule,
      seat_class: seat_class,
      available_seats: 10
    )
  end

  let(:valid_params) do
    {
      flight_number: "AI101",
      source: "Delhi",
      destination: "Mumbai",
      date: Date.today.to_s,
      class_type: "economy",
      passengers: 2
    }
  end

  it "books a flight successfully" do
    result = FlightBookingService.new(valid_params).book_flight

    expect(result[:success]).to be true
    expect(result[:message]).to eq("Booking successful")
    expect(result[:data].available_seats).to eq(8) # 10 - 2
  end

  it "returns error if flight not found" do
    params = valid_params.merge(flight_number: "XX999")
    result = FlightBookingService.new(params).book_flight

    expect(result[:success]).to be false
    expect(result[:status]).to eq(404)
    expect(result[:message]).to eq("Flight not found")
  end

  it "returns error if no schedule found" do
    flight_schedule.destroy
    result = FlightBookingService.new(valid_params).book_flight

    expect(result[:success]).to be false
    # expect(result[:error]).to include("No flight schedule")
  end

  it "returns error if seat class not found" do
    params = valid_params.merge(class_type: "luxury")
    result = FlightBookingService.new(params).book_flight

    expect(result[:success]).to be false
    expect(result[:message]).to eq("Seat class not found")
  end

  it "returns error if insufficient seats" do
    params = valid_params.merge(passengers: 20)
    result = FlightBookingService.new(params).book_flight

    expect(result[:success]).to be false
    expect(result[:message]).to eq("No seats available")
    expect(result[:status]).to eq(409)
  end
    context "when source airport is not found" do
        it "returns an error" do
            params = valid_params.merge(source: "NonExistentCity")
            result = FlightBookingService.new(params).book_flight
            expect(result[:status]).to eq(404)
        end
    end
     context "when destination airport is not found" do
        it "returns an error" do
            params = valid_params.merge(destination: "NonExistentCity")
            result = FlightBookingService.new(params).book_flight
            expect(result[:message]).to eq("Flight not found")

            expect(result[:status]).to eq(404)
        end
    end
    context "when seat info for the class is not available on the selected date" do
        it "returns an error" do
            params = valid_params.merge(class_type: "RandomClass")
            result = FlightBookingService.new(params).book_flight

            expect(result[:status]).to eq(404)
            expect(result[:message]).to eq("Seat class not found")
            expect(result[:status]).to eq(404)
        end
    end
end
# end
