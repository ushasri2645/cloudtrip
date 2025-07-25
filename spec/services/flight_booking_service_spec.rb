require 'rails_helper'

RSpec.describe FlightBookingService do
  let!(:source_airport)      { Airport.create!(city: "Mumbai", code: "BOM") }
  let!(:destination_airport) { Airport.create!(city: "Delhi", code: "DEL") }

  let!(:flight) do
    Flight.create!(
      flight_number: "AI101",
      source: source_airport,
      destination: destination_airport,
      departure_time: Time.zone.now,
      is_recurring: false,
      duration_minutes: 120
    )
  end

  let!(:seat_class) { SeatClass.create!(name: "Economy") }

  let!(:schedule) do
    FlightSchedule.create!(
      flight: flight,
      flight_date: Time.zone.today
    )
  end

  let!(:seat) do
    FlightScheduleSeat.create!(
      flight_schedule: schedule,
      seat_class: seat_class,
      available_seats: 5
    )
  end

  describe "#book_flight" do
    context "when enough seats are available" do
      it "successfully books the flight and updates available seats" do
        service = described_class.new(schedule: schedule, seat: seat, passengers: 2)
        result = service.book_flight

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Booking successful")
        expect(result[:data].reload.available_seats).to eq(3)
      end
    end

    context "when not enough seats are available" do
      it "fails and returns an appropriate error" do
        service = described_class.new(schedule: schedule, seat: seat, passengers: 10)
        result = service.book_flight

        expect(result[:success]).to be false
        expect(result[:message]).to eq("No seats available")
        expect(result[:status]).to eq(409)
        expect(seat.reload.available_seats).to eq(5)
      end
    end
  end

  after(:each) do
    FlightScheduleSeat.destroy_all
    FlightSchedule.destroy_all
    SeatClass.destroy_all
    Flight.destroy_all
    Airport.destroy_all
  end
end
