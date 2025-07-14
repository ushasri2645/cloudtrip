require "rails_helper"

RSpec.describe FlightDataService do
  describe ".load_unique_cities" do
    let(:data_path) { Rails.root.join("spec/testData/testData.txt") }

    before do
        Time.use_zone("Asia/Kolkata") do
        allow(DynamicPricingService).to receive(:calculate_price).and_return(120.0)

        today = Time.zone.today.strftime("%Y-%m-%d")
        past_time = (1.hour.ago.in_time_zone).strftime("%I:%M %p")
        future_time = (2.hours.from_now.in_time_zone).strftime("%I:%M %p")

        FileUtils.mkdir_p(data_path.dirname)
        File.write(data_path, <<~DATA)
            F101,Bangalore,London,2025-07-12,03:23 PM,2025-07-13,09:23 AM,100,500,50,30,20,50,30,20
            F102,Bangalore,New York,2025-07-04,03:23 PM,2025-07-12,09:23 PM,10,900,5,3,2,5,3,2
            F103,Chennai,London,2025-07-05,03:23 PM,2025-07-12,09:23 PM,50,600,20,20,10,20,20,10
        DATA
        end
    end

    it "returns unique sorted cities from file" do
      result = FlightDataService.load_unique_cities

      expect(result).to eq(
        [ "Bangalore", "Chennai", "London", "New York" ]
      )
    end
  end

  describe ".read_flights" do
    let(:data_path) { Rails.root.join("spec/testData/testData.txt") }

    before do
      Time.use_zone("Asia/Kolkata") do
        FileUtils.mkdir_p(data_path.dirname)
        File.write(data_path, <<~DATA)
          F101,Bangalore,London,2025-07-12,03:23 PM,4500,100,120,50,60,30,40
          F102,Bangalore,New York,2025-07-14,10:00 AM,5000,80,100,40,50,20,30
        DATA

        stub_const("FlightDataService::DATA_PATH", data_path)
      end
    end

    it "parses flight data from file into expected hash structure" do
      flights = FlightDataService.read_flights

      expect(flights.size).to eq(2)

      expect(flights.first).to eq(
        {
          flight_number:      "F101",
          source:             "Bangalore",
          destination:        "London",
          departure_date:     "2025-07-12",
          departure_time:     "03:23 PM",
          price:              4500.0,
          economy_seats:      100,
          economy_total:      120,
          business_seats:     50,
          business_total:     60,
          first_class_seats:  30,
          first_class_total:  40
        }
      )

      expect(flights.last[:flight_number]).to eq("F102")
      expect(flights.last[:price]).to eq(5000.0)
    end
  end
end
