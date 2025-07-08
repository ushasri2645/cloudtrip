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

  describe "GET /flights/index" do
    it "returns http success" do
      get "/flights/index"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Search")
    end
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
