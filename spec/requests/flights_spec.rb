require "rails_helper"

RSpec.describe "Api::Flights", type: :request do
  let(:flights_path) { Rails.configuration.flights_file }
  let(:seats_path)   { Rails.configuration.seats_file }

  before do
    FileUtils.mkdir_p(flights_path.dirname)
    FileUtils.mkdir_p(seats_path.dirname)

    today        = Date.today.strftime("%Y-%m-%d")
    past_time    = (1.hour.ago).strftime("%I:%M %p")
    future_time  = (2.hours.from_now).strftime("%I:%M %p")

    File.write(flights_path, <<~FLIGHTS)
      F101,Bangalore,London,2025-07-12,03:23 PM,2025-07-13,09:23 AM,100,500,50,30,20,50,30,20
      F102,Bangalore,New York,2025-07-04,03:23 PM,2025-07-12,09:23 PM,10,900,5,3,2,5,3,2
      F103,Chennai,London,2025-07-05,03:23 PM,2025-07-12,09:23 PM,50,600,20,20,10,20,20,10
      F200,Bangalore,London,#{today},#{past_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
      F201,Bangalore,London,#{today},#{future_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
    FLIGHTS

    File.write(seats_path, <<~SEATS)
      F101,50,30,20,50,30,20
      F102,5,3,2,5,3,2
      F103,20,20,10,20,20,10
      F200,50,30,20,50,30,20
      F201,50,30,20,50,30,20
    SEATS

    allow(DynamicPricingService).to receive(:calculate_price).and_return(120.0)
  end

  describe "POST /api/flights" do
    it "returns matching flights in the response" do
      post "/api/flights", params: { source: "Bangalore", destination: "London", date: "2025-07-12", class_type: "economy" }
      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["flights"].map { |f| f["flight_number"] }).to include("F101")
    end

    it "returns no flights if no match found" do
      post "/api/flights", params: { source: "Mumbai", destination: "Paris", date: "2025-07-12" }
      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["flights"]).to be_empty
      expect(json["message"]).to eq("No matching flights available")
    end

    it "matches case-insensitive source/destination" do
      post "/api/flights", params: { source: "bangalore", destination: "london", date: "2025-07-12", class_type: "economy" }
      json = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(json["flights"].map { |f| f["flight_number"] }).to include("F101")
    end

    it "does not return flights when not enough seats" do
      post "/api/flights", params: { source: "Bangalore", destination: "London", date: "2025-07-12", passengers: 150, class_type: "economy" }
      json = response.parsed_body

      expect(json["flights"]).to be_empty
      expect(json["message"]).to eq("No matching flights available")
    end

    it "calculates total fare correctly for first class" do
      post "/api/flights", params: { source: "Bangalore", destination: "London", date: "2025-07-12", passengers: 2, class_type: "first_class" }
      json = response.parsed_body

      expect(json["flights"].first["total_fare"]).to eq(2240.0)
    end

    it "returns error when source and destination are same" do
      post "/api/flights", params: { source: "Chennai", destination: "Chennai", date: "2025-07-12" }
      json = response.parsed_body

      expect(json["errors"]).to include("Source and Destination must be different")
    end

    it "includes only flights in future for today" do
      post "/api/flights", params: { source: "Bangalore", destination: "London", date: Date.today.strftime("%Y-%m-%d"), class_type: "economy" }
      json = response.parsed_body

      expect(json["flights"].map { |f| f["flight_number"] }).to include("F201")
      expect(json["flights"].map { |f| f["flight_number"] }).not_to include("F200")
    end
  end

  describe "POST /api/book" do
    it "books successfully and reduces seat count" do
      before_count = File.readlines(seats_path).find { |l| l.start_with?("F101") }.split(",")[1].to_i

      post "/api/book", params: {
        flight: { flight_number: "F101", class_type: "economy" },
        passengers: 3
      }

      json = response.parsed_body
      after_count = File.readlines(seats_path).find { |l| l.start_with?("F101") }.split(",")[1].to_i

      expect(response).to have_http_status(:ok)
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to eq("Booking successful!")
      expect(after_count).to eq(before_count - 3)
    end

    it "fails if not enough seats" do
      post "/api/book", params: {
        flight: { flight_number: "F101", class_type: "first_class" },
        passengers: 25
      }

      json = response.parsed_body

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to include("Not enough seats")
    end
  end
end
