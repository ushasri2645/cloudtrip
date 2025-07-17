require "rails_helper"

RSpec.describe FlightsController, type: :request do
  let(:flights_path) { Rails.configuration.flights_file }
  let(:seats_path)   { Rails.configuration.seats_file }

  before do
    FileUtils.mkdir_p(flights_path.dirname)
    FileUtils.mkdir_p(seats_path.dirname)

    today        = Time.zone.today.strftime("%Y-%m-%d")
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

  describe "POST /flights/search" do
    it "renders the index with matching flights" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London",
        date: "2025-07-12",
        class_type: "economy"
      }

      expect(response.body).to include("Bangalore")
      expect(response.body).to include("London")
      expect(response.body).to include("F101")
    end

    it "shows error when no matching flights found" do
      post "/flights/search", params: {
        source: "Mumbai",
        destination: "Paris",
        date: "2025-07-12"
      }

      expect(response.body).to include("No Flights Available")
    end

    it "shows error when source and destination are the same" do
      post "/flights/search", params: {
        source: "Chennai",
        destination: "Chennai",
        date: "2025-07-12"
      }

      expect(response.body).to include("Source and Destination must be different.")
    end

    it "defaults to economy when class_type is missing" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London",
        date: "2025-07-12"
      }

      expect(response.body).to include("economy")
    end

    it "filters out past flights if date is today" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London",
        date: Time.zone.today.strftime("%Y-%m-%d"),
        class_type: "economy"
      }

      expect(response.body).to include("F201")
      expect(response.body).not_to include("F200")
    end
  end

  describe "POST /flights/book" do
    it "books flight and reduces seat count" do
      before_count = File.readlines(seats_path).find { |l| l.start_with?("F101") }.split(",")[1].to_i

      post "/flights/book", params: {
        flight_number: "F101",
        class_type: "economy",
        passengers: 2
      }

      after_count = File.readlines(seats_path).find { |l| l.start_with?("F101") }.split(",")[1].to_i

      expect(after_count).to eq(before_count - 2)
      follow_redirect!
      expect(response.body).to include("Booking successful!")
    end

    it "does not book if not enough seats" do
      post "/flights/book", params: {
        flight_number: "F101",
        class_type: "first_class",
        passengers: 50
      }

      follow_redirect!
      expect(response.body).to include("Not enough seats available.")
    end
  end
end
