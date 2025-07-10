require "rails_helper"

RSpec.describe "Flights", type: :request do
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
        F200,Bangalore,London,#{today},#{past_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
        F201,Bangalore,London,#{today},#{future_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
      DATA
    end
  end

  describe "POST /flights/search" do
    context "when matching flights exist" do
      it "returns matching flights in the response" do
        post "/flights/search", params: { source: "Bangalore", destination: "London", date: "2025-07-12", class_type: "economy" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Bangalore")
        expect(response.body).to include("London")
        expect(response.body).to include("F101")
      end
    end

    context "when no matching flights exist" do
      it "shows flash alert" do
        post "/flights/search", params: { source: "Mumbai", destination: "Paris", date: "2025-07-12" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No Flights Available")
      end
    end

    context "case-insensitive matching" do
      it "matches source and destination regardless of case" do
        post "/flights/search", params: { source: "bangalore", destination: "london", date: "2025-07-12", class_type: "economy" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F101")
      end
    end

    context "when passenger count is greater than available seats" do
        it "does not return the flight" do
        post "/flights/search", params: {
            source: "Bangalore",
            destination: "London",
            date: "2025-07-12",
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
          date: "2025-07-12",
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
          date: "2025-07-12",
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
          date: "2025-07-12",
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
          date: "2025-07-12",
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
          date: "2025-07-12",
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
          date: "2025-07-12",
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
            date: "2025-07-12",
            passengers: 2,
            class_type: "first_class"
          }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("$2240.00")
      end
    end

    context "when origin and destination are the same" do
      it "shows an error and no flights" do
        post "/flights/search", params: {
          source: "Chennai",
          destination: "Chennai",
          date: "2025-07-12",
          passengers: 1
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Origin and Destination must be different.")
        expect(response.body).not_to include("F101")
        expect(response.body).not_to include("F103")
      end
    end
     context "when searching flights for today with past and future times" do
      before do
        Time.use_zone("Asia/Kolkata") do
          today = Time.zone.today.strftime("%Y-%m-%d")
          past_time = (1.hour.ago).strftime("%I:%M %p")
          future_time = (2.hours.from_now).strftime("%I:%M %p")

          File.write(data_path, <<~DATA)
            F200,Bangalore,London,#{today},#{past_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
            F201,Bangalore,London,#{today},#{future_time},#{today},09:23 AM,100,500,50,30,20,50,30,20
          DATA

          post "/flights/search", params: {
            source: "Bangalore",
            destination: "London",
            date: today,
            class_type: "economy"
          }

          @today = today
        end
      end

      it "excludes flights whose departure time has already passed" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("F201")
        expect(response.body).not_to include("F200")
      end
    end
end

  describe "POST /flights/book" do
      context "when booking is successful" do
        it "reduces seat count and redirects to root with success notice" do
          original_lines = File.readlines(data_path)
          economy_seats_before = original_lines[0].split(",")[9].to_i

          post "/flights/book", params: {
            flight_number: "F101",
            class_type: "economy",
            passengers: 3
          }

          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("Booking successful")

          updated_lines = File.readlines(data_path)
          updated_economy_seats = updated_lines[0].split(",")[9].to_i
          expect(updated_economy_seats).to eq(economy_seats_before - 3)
        end
      end

      context "when there are not enough seats" do
        it "does not update file and shows error message" do
          post "/flights/book", params: {
            flight_number: "F101",
            class_type: "first_class",
            passengers: 25
          }
          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("Not enough seats available")
          unchanged_seats = File.readlines(data_path)[0].split(",")[11].to_i
          expect(unchanged_seats).to eq(20)
        end
      end
  end
end
