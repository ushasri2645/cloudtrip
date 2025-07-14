require "rails_helper"

RSpec.describe "Flights", type: :request do
  DATA_PATH = Rails.configuration.flight_data_file

  before(:each) do
    FileUtils.mkdir_p(DATA_PATH.dirname)
    File.write(DATA_PATH, <<~DATA)
      F101,Bangalore,London,2025-07-12,03:23 PM,2025-07-13,09:23 AM,100,500,50,30,20,50,30,20
      F102,Bangalore,New York,2025-07-04,03:23 PM,2025-07-12,09:23 PM,10,900,5,3,2,5,3,2
      F103,Chennai,London,2025-07-05,03:23 PM,2025-07-12,09:23 PM,50,600,20,20,10,20,20,10
    DATA
  end

  describe "GET /flights/search" do
    it "renders the index page" do
      get "/flights/search", params: { source: "Bangalore", destination: "London" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /flights/search" do
    it "renders matching flights if any exist" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London"
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Bangalore")
      expect(response.body).to include("London")
    end

    it "shows 'No Flights Available' if none found" do
      post "/flights/search", params: {
        source: "Mumbai",
        destination: "Paris",
        date: "2025-07-12"
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("No Flights Available")
    end
  end
end

RSpec.describe "Api::Flights", type: :request do
  describe "GET /api/cities" do
    it "returns cities in JSON" do
      get "/api/cities"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["cities"]).to eq([ "Bangalore", "Chennai", "London", "New York" ])
    end
  end

  describe "POST /api/search" do
    context "with valid parameters and matching flight" do
      before do
        allow(DynamicPricingService).to receive(:calculate_price).and_return(100.0)
      end

      it "returns matching flights and message" do
        post "/api/flights", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-12",
          class_type: "economy",
          passengers: 2
        }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body

        expect(json["message"]).to eq("Flights found")
        expect(json["flights"]).not_to be_empty
        expect(json["flights"].first["source"]).to eq("Bangalore")
      end
    end

    context "with invalid parameters" do
      it "returns error messages" do
        post "/api/flights", params: {
          source: "",
          destination: "",
          date: ""
        }

        expect(response).to have_http_status(:bad_request)
        json = response.parsed_body

        expect(json["errors"]).to include("Source is missing", "Destination is missing", "Date is missing")
      end
    end

    context "when no matching flights are found" do
      it "returns empty flights and message" do
        post "/api/flights", params: {
          source: "Mumbai",
          destination: "Paris",
          date: "2025-07-14"
        }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body

        expect(json["message"]).to eq("No matching flights available")
        expect(json["flights"]).to be_empty
      end
    end
  end
end
