require 'rails_helper'

RSpec.describe FlightSeat, type: :model do
  let(:source) { Airport.create!(code: "SRC", city: "CityA") }
  let(:destination) { Airport.create!(code: "DST", city: "CityB") }

  let(:flight) {
  Flight.create!(
    flight_number: "AI202",
    source: source,
    destination: destination,
    departure_datetime: DateTime.now + 1.day,
    arrival_datetime: DateTime.now + 2.days,
    total_seats: 180,
    price: 4500.00
  )
}

  let(:seat_class) { SeatClass.create!(name: "Economy #{SecureRandom.hex(4)}") }

  after(:each) do
    FlightSeat.delete_all
    SeatClass.delete_all
    Flight.delete_all
    Airport.delete_all
  end

  context "validations" do
    it "is valid with proper total and available seats" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: 10, available_seats: 5)
      expect(flight_seat).to be_valid
    end

    it "is invalid if available_seats is greater than total_seats" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: 5, available_seats: 6)
      expect(flight_seat).not_to be_valid
      expect(flight_seat.errors[:available_seats]).to include("can't be more than total seats")
    end

    it "is valid when available_seats equals total_seats" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: 5, available_seats: 5)
      expect(flight_seat).to be_valid
    end

    it "is invalid when total_seats is nil" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: nil, available_seats: 5)
      expect(flight_seat).not_to be_valid
      expect(flight_seat.errors[:total_seats]).to include("can't be blank")
    end

    it "is invalid when available_seats is nil" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: 5, available_seats: nil)
      expect(flight_seat).not_to be_valid
      expect(flight_seat.errors[:available_seats]).to include("can't be blank")
    end

    it "is invalid when available_seats or total_seats is negative" do
      flight_seat = FlightSeat.new(flight: flight, seat_class: seat_class, total_seats: -1, available_seats: -1)
      expect(flight_seat).not_to be_valid
      expect(flight_seat.errors[:total_seats]).to include("must be greater than or equal to 0")
      expect(flight_seat.errors[:available_seats]).to include("must be greater than or equal to 0")
    end
  end
end
