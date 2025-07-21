require 'rails_helper'

RSpec.describe "Api::FlightsController", type: :request do
  describe "POst /api/flights/search" do
    before(:each) do
      ClassPricing.delete_all
      FlightSeat.delete_all
      Flight.delete_all
      SeatClass.delete_all
      Airport.delete_all
    end

    let!(:economy_class) { SeatClass.create!(name: "Economy") }

    let!(:mumbai) { Airport.create!(code: "BOM", city: "Mumbai") }
    let!(:delhi)  { Airport.create!(code: "DEL", city: "Delhi") }

    let!(:flight) do
      Flight.create!(
        flight_number: "F101",
        source: mumbai,
        destination: delhi,
        departure_datetime: "2025-07-20 10:00:00",
        arrival_datetime: "2025-07-20 12:00:00",
        price: 500.0,
        total_seats: 100
      )
    end

    let!(:flight_seat) do
      FlightSeat.create!(
        flight: flight,
        seat_class: economy_class,
        total_seats: 100,
        available_seats: 50
      )
    end

    let!(:pricing) do
      ClassPricing.create!(
        flight_id: flight.id,
        seat_class_id: economy_class.id,
        multiplier: 1,
      )
    end

    context "when valid search parameters are provided" do
      it "returns a list of matching flights with 200 status" do
        post "/api/flights", params: {
          source: "Mumbai",
          destination: "Delhi",
          date: "2025-07-20",
          class_type: "Economy",
          passengers: 2
        }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["flights"]).not_to be_empty
      end
    end

    context "when missing or invalid parameters are provided" do
      it "returns 400 Bad Request with validation errors" do
        post "/api/flights", params: {
          source: "", destination: "", date: "", class_type: "", passengers: ""
        }

        expect(response).to have_http_status(:bad_request)
        json = response.parsed_body
        expect(json["errors"]).not_to be_empty
      end
    end

    context "when no available seats for given class and passengers" do
      it "returns 409 Conflict with no flights message" do
        flight_seat.update(available_seats: 0)

        post "/api/flights", params: {
          source: "Mumbai",
          destination: "Delhi",
          date: "2025-07-20",
          class_type: "Economy",
          passengers: 2
        }

        expect(response).to have_http_status(:conflict)
        json = response.parsed_body
        expect(json["message"]).to eq("All flights on 20-Jul-2025 between Mumbai and Delhi are fully booked.")
      end
    end
  end
end
