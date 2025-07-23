require 'rails_helper'

RSpec.describe Flight, type: :model do
  after(:each) do
    BaseFlightSeat.delete_all
    Flight.delete_all
    Airport.delete_all
  end

  it "is valid with all required attributes" do
    airport1 = Airport.create(city: "Chennai", code: "MAA")
    airport2 = Airport.create(city: "Mumbai", code: "BOM")
    flight = Flight.new(
      flight_number: "6E102",
      source: airport1,
      destination: airport2,
      departure_time: (1.day.from_now).strftime("%H:%M:%S"),
      duration_minutes: 120
    )
    expect(flight).to be_valid
  end

  it "is not valid without flight_number" do
    expect(Flight.new).not_to be_valid
  end

  it { should belong_to(:source).class_name('Airport') }
  it { should belong_to(:destination).class_name('Airport') }
  it { should have_many(:base_flight_seats) }
  it { should have_many(:flight_schedules) }
  it { should have_one(:flight_recurrence) }
end
