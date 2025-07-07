require "rails_helper"

RSpec.describe "Flights", type: :request do
  let(:data_path) { Rails.root.join("spec/testData/testData.txt") }

  before do
    FileUtils.mkdir_p(data_path.dirname)
    File.write(data_path, <<~DATA)
      F101,Bangalore,London,2025-07-04,03:23 PM,09:23 PM,100,500,50,30,20,50,30,20
      F102,Bangalore,New York,2025-07-04,05:00 AM,02:00 PM,100,900,5,3,2,5,3,2
      F103,Chennai,London,2025-07-05,10:00 AM,04:00 PM,50,600,20,20,10,20,20,10
    DATA
  end
  describe "POST /flights/search" do
    context "when matching flights exist" do
      it "returns matching flights in the response" do
        post "/flights/search", params: { source: "Bangalore", destination: "London", date: "2025-07-04", class_type: "economy" }

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

    context "case-insensitive matching" do
      it "matches source and destination regardless of case" do
        post "/flights/search", params: { source: "bangalore", destination: "london", date: "2025-07-04", class_type: "economy" }
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
            passengers: 150,
            class_type: "economy"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
        expect(response.body).not_to include("F101")
        end
    end

    context "when searching for economy class flights" do
      it "returns flights with enough economy seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 10,
          class_type: "economy"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F101")
      end

      it "does not return flights if not enough economy seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 60,
          class_type: "economy"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
        expect(response.body).not_to include("F101")
      end
    end

    context "when searching for business class flights" do
      it "returns flights with enough business seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 10,
          class_type: "business"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F101")
      end

      it "does not return flights if not enough business seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 35,
          class_type: "business"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
        expect(response.body).not_to include("F101")
      end
    end

    context "when searching for first class flights" do
      it "returns flights with enough first class seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 10,
          class_type: "first_class"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F101")
      end

      it "does not return flights if not enough first class seats" do
        post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 25,
          class_type: "first_class"
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
        expect(response.body).not_to include("F101")
      end
    end


    context "when searching for first class flights" do
      it "calculates the correct total fare" do
          post "/flights/search", params: {
          source: "Bangalore",
          destination: "London",
          date: "2025-07-04",
          passengers: 2,
          class_type: "first_class"
          }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("$2000.00")
      end
    end

  context "when origin and destination are the same" do
      it "shows an error and no flights" do
        post "/flights/search", params: {
          source: "Chennai",
          destination: "Chennai",
          date: "2025-07-04",
          passengers: 1
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Origin and Destination must be different.")
        expect(response.body).not_to include("F101")
        expect(response.body).not_to include("F103")
      end
    end
  end
end
