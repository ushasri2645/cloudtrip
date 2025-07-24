require 'rails_helper'

RSpec.describe "Api::BookingsController", type: :request do
  let(:source_airport) { Airport.create!(city: "Mumbai", code: "Mumbai Airport") }
  let(:destination_airport) { Airport.create!(city: "Delhi", code: "Delhi Airport") }
  let(:flight) {
    Flight.create!(
      flight_number: "AI123",
      source: source_airport,
      destination: destination_airport,
      departure_time: Time.zone.today.change(hour: 10),
      duration_minutes: 120,
      is_recurring: false,
    )
  }
  let(:seat_class) { SeatClass.create!(name: "Economy") }
  let(:schedule_date) { Time.zone.today }
  let(:schedule) {
    flight.flight_schedules.create!(flight_date: schedule_date)
  }
  let!(:seat) {
    FlightScheduleSeat.create!(
      flight_schedule: schedule,
      seat_class: seat_class,
      available_seats: 10
    )
  }

  let(:valid_params) {
    {
      passengers: 2,
      flight: {
        flight_number: flight.flight_number,
        source: source_airport.city,
        destination: destination_airport.city,
        class_type: "economy",
        departure_date: schedule_date,
        departure_time: "10:00"
      }
    }
  }

  describe "POST /api/book" do
    it "books successfully with valid data" do
      post "/api/book", params: valid_params
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to eq("Booking successful") # assuming this is your service message
      expect(json["data"]).to be_present
    end

    it "returns 404 when flight is not found" do
      invalid_params = valid_params.deep_dup
      invalid_params[:flight][:flight_number] = "INVALID"

      post "/api/book", params: invalid_params
      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Flight not found")
    end

    it "returns 404 when schedule is missing" do
      schedule.destroy
      post "/api/book", params: valid_params

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("No schedule available on this date")
    end

    it "returns 404 when seat class is not found" do
      invalid_params = valid_params.deep_dup
      invalid_params[:flight][:class_type] = "luxury"

      post "/api/book", params: invalid_params
      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Seat class not found")
    end

    it "returns 404 when seat info is missing" do
      seat.destroy
      post "/api/book", params: valid_params
      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("No seat info for this class on the selected date")
    end

    it "returns 409 when not enough seats are available" do
      seat.update!(available_seats: 1)
      post "/api/book", params: valid_params.merge(passengers: 2)

      expect(response).to have_http_status(:conflict)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Not enough seats")
    end

    it "returns 422 when booking service fails" do
      # simulate failure inside the booking service
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return(
        { success: false, message: "Unexpected error while booking" }
      )

      post "/api/book", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Unexpected error while booking")
    end
  end
end
