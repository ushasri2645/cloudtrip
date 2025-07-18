require 'rails_helper'

RSpec.describe Flight, type: :model do
  after(:all) do
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
      departure_datetime: DateTime.now,
      arrival_datetime: DateTime.now + 2.hours,
      total_seats: 180,
      price: 4500.0
    )
    expect(flight).to be_valid
  end

  it "is not valid without flight_number" do
    expect(Flight.new).not_to be_valid
  end

  it { should belong_to(:source).class_name('Airport') }
  it { should belong_to(:destination).class_name('Airport') }

  it { should have_many(:flight_seats) }
  it { should have_many(:class_pricings) }

  it "is not valid if arrival is before departure" do
    airport1 = Airport.create(city: "Chennai", code: "MAA")
    airport2 = Airport.create(city: "Mumbai", code: "BOM")
    flight = Flight.new(
      flight_number: "AI202",
      source: airport1,
      destination: airport2,
      departure_datetime: DateTime.now,
      arrival_datetime: DateTime.now - 1.hour,
      total_seats: 100,
      price: 3000.0
    )
    expect(flight).not_to be_valid
    expect(flight.errors[:arrival_datetime]).to include("must be after departure")
  end
end
