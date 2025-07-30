require 'rails_helper'

RSpec.describe "Api::FlightsController", type: :request do
  describe "POst /api/flights/search" do
    before(:each) do
      BaseFlightSeat.delete_all
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
        departure_time: (Time.zone.now).strftime("%H:%M:%S"),
        duration_minutes: 120
      )
    end

    let!(:base_flight_seat) do
      BaseFlightSeat.create!(
        flight: flight,
        seat_class: economy_class,
        total_seats: 100,
        price: 3500
      )
    end
    let!(:flight_schedule) do
      FlightSchedule.create!(
        flight: flight,
        flight_date: Time.zone.today
      )
    end

    let!(:flight_schedule_seat) do
      FlightScheduleSeat.create!(
        flight_schedule: flight_schedule,
        seat_class: economy_class,
        available_seats: 80
      )
    end

    context "when valid search parameters are provided" do
      it "returns a list of matching flights with 200 status" do
        post "/api/flights", params: {
          source: "Mumbai",
          destination: "Delhi",
          date: Time.zone.today.to_s,
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
        flight_schedule_seat.update!(available_seats: 0)

        post "/api/flights", params: {
          source: "Mumbai",
          destination: "Delhi",
          date: Time.zone.today.to_s,
          class_type: "Economy",
          passengers: 2
        }

        expect(response).to have_http_status(:conflict)
        json = response.parsed_body
        expect(json["message"]).to eq("All seats are booked in economy class on #{Time.zone.today}")
      end
    end
  end
end
