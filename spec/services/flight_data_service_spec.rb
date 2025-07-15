require "rails_helper"

RSpec.describe FlightDataService do
  let(:flights_path) { Rails.root.join("spec/testData/flights_testData.txt") }
  let(:seats_path)   { Rails.root.join("spec/testData/seats_testData.txt") }

  before do
    FileUtils.mkdir_p(flights_path.dirname)

    File.write(flights_path, <<~FLIGHTS)
      F101,Bangalore,London,2025-07-12,03:23 PM,2025-07-13,09:23 AM,100,500
      F102,Bangalore,New York,2025-07-04,03:23 PM,2025-07-12,09:23 PM,10,900
      F103,Chennai,London,2025-07-05,03:23 PM,2025-07-12,09:23 PM,50,600
    FLIGHTS

    File.write(seats_path, <<~SEATS)
      F101,50,30,20,50,30,20
      F102,5,3,2,5,3,2
      F103,20,20,10,20,20,10
    SEATS

    allow(Rails.configuration).to receive(:flights_file).and_return(flights_path)
    allow(Rails.configuration).to receive(:seats_file).and_return(seats_path)

    Rails.cache.clear
  end

  describe ".load_unique_cities" do
    it "returns unique sorted cities from flight data" do
      cities = FlightDataService.load_unique_cities
      expect(cities).to eq(["Bangalore", "Chennai", "London", "New York"])
    end
  end

  describe ".read_flights" do
    it "parses and merges flight and seat data correctly" do
      flights = FlightDataService.read_flights

      expect(flights.size).to eq(3)

      expect(flights.first).to eq(
        {
          flight_number:      "F101",
          source:             "Bangalore",
          destination:        "London",
          departure_date:     "2025-07-12",
          departure_time:     "03:23 PM",
          arrival_date:       "2025-07-13",
          arrival_time:       "09:23 AM",
          total_seats:         100,
          price:               500.0,
          economy_seats:       50,
          business_seats:      30,
          first_class_seats:   20,
          economy_total:       50,
          business_total:      30,
          first_class_total:   20
        }
      )
    end
  end

  describe ".update_seat_availability" do
    it "reduces seats if enough available" do
      result = FlightDataService.update_seat_availability("F101", "economy", 5)
      expect(result[:updated]).to be true
    end

    it "does not reduce seats if not enough available" do
      result = FlightDataService.update_seat_availability("F101", "first_class", 100)
      expect(result[:updated]).to be false
      expect(result[:error]).to include("Not enough seats")
    end

    it "returns error on invalid class_type" do
      result = FlightDataService.update_seat_availability("F101", "invalid_class", 1)
      expect(result[:updated]).to be false
      expect(result[:error]).to include("Invalid class_type")
    end
  end
end
