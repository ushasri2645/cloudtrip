require 'rails_helper'

RSpec.describe BaseFlightSeat, type: :model do
  let(:source) { Airport.create!(code: "SRC", city: "CityA") }
  let(:destination) { Airport.create!(code: "DST", city: "CityB") }

  let(:flight) {
  Flight.create!(
    flight_number: "AI202",
    source: source,
    destination: destination,
    departure_time: (1.day.from_now).strftime("%H:%M:%S"),
    duration_minutes: 120
  )
}

  let(:seat_class) { SeatClass.create!(name: "Economy #{SecureRandom.hex(4)}") }

  after(:each) do
    BaseFlightSeat.delete_all
    SeatClass.delete_all
    Flight.delete_all
    Airport.delete_all
  end

  context "validations" do
    it "is valid with proper total and available seats" do
      flight_seat = BaseFlightSeat.new(flight: flight, seat_class: seat_class, total_seats: 10)
      expect(flight_seat).to be_valid
    end


    it "is invalid when total_seats is nil" do
      flight_seat = BaseFlightSeat.new(flight: flight, seat_class: seat_class, total_seats: nil)
      expect(flight_seat).not_to be_valid
      expect(flight_seat.errors[:total_seats]).to include("can't be blank")
    end
  end
end
