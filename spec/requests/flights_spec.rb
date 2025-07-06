require "rails_helper"

RSpec.describe "Flights", type: :request do
  DATA_PATH = Rails.root.join("data", "data.txt")

  before(:all) do
    FileUtils.mkdir_p(DATA_PATH.dirname)
    File.write(DATA_PATH, <<~DATA)
      F101,Bangalore,London,2025-07-04,03:23 PM,09:23 PM,100,500,50,30,20
      F102,Bangalore,New York,2025-07-04,05:00 AM,02:00 PM,0,900,5,3,2
      F103,Chennai,London,2025-07-05,10:00 AM,04:00 PM,50,600,20,20,10
    DATA
  end

  after(:all) do
    File.delete(DATA_PATH) if File.exist?(DATA_PATH)
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
        destination: "Paris"
      }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("No Flights Available")
    end
  end
end
