require "rails_helper"

RSpec.describe "Flights", type: :request do
  let(:data_path) { Rails.root.join("spec/testData/testData.txt") }

  before do
    FileUtils.mkdir_p(data_path.dirname)
    File.write(data_path, <<~DATA)
      F101,Bangalore,London,2025-07-04,03:23 PM,09:23 PM,100,500,50,30,20
      F102,Bangalore,New York,2025-07-04,05:00 AM,02:00 PM,0,900,5,3,2
      F103,Chennai,London,2025-07-05,10:00 AM,04:00 PM,50,600,20,20,10
    DATA
  end
  describe "POST /flights/search" do
    context "when matching flights exist" do
      it "returns matching flights in the response" do
        post "/flights/search", params: { source: "Bangalore", destination: "London", date: "2025-07-04" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bangalore")
        expect(response.body).to include("London")
        expect(response.body).to include("F101")
      end
    end

    context "when no matching flights exist" do
      it "shows flash alert" do
        post "/flights/search", params: { source: "Mumbai", destination: "Paris", date: "2025-07-04" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
      end
    end

    context "when seats are zero" do
      it "does not return flights with 0 seats" do
        post "/flights/search", params: { source: "Bangalore", destination: "New York", date: "2025-07-04" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
        expect(response.body).not_to include("F102")
      end
    end

    context "case-insensitive matching" do
      it "matches source and destination regardless of case" do
        post "/flights/search", params: { source: "bangalore", destination: "london", date: "2025-07-04" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F101")
      end
    end

    context "when passenger count is greater than available seats" do
    it "does not return the flight" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London",
        date: "2025-07-04",
        passengers: 150
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No Flights Available")
      expect(response.body).not_to include("F101")
    end
  end

  context "when passenger count is within available seats" do
    it "returns the flight" do
      post "/flights/search", params: {
        source: "Bangalore",
        destination: "London",
        date: "2025-07-04",
        passengers: 3
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("F101")
    end
  end
  end
end
