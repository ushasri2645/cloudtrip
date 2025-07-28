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
      expect(json["message"]).to eq("Booking successful")
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
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return(
        { success: false, message: "Unexpected error while booking" }
      )

      post "/api/book", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Unexpected error while booking")
    end

    it "defaults to 1 passenger in one-way booking if 0 is given" do
      params = valid_params.deep_dup
      params[:passengers] = 0
      post "/api/book", params: params
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
    end
  end

  describe "POST /api/round_trip_booking" do
    let(:return_flight) {
      Flight.create!(
        flight_number: "AI124",
        source: destination_airport,
        destination: source_airport,
        departure_time: Time.zone.today.change(hour: 18),
        duration_minutes: 120,
        is_recurring: false,
      )
    }

    let(:return_schedule_date) { schedule_date + 5 }

    let(:return_schedule) {
      return_flight.flight_schedules.create!(flight_date: return_schedule_date)
    }

    let!(:return_seat) {
      FlightScheduleSeat.create!(
        flight_schedule: return_schedule,
        seat_class: seat_class,
        available_seats: 10
      )
    }

    let(:onward_booking) {
      {
        flight_number: flight.flight_number,
        source: source_airport.city,
        destination: destination_airport.city,
        class_type: seat_class.name.downcase,
        passengers: 2,
        departure_date: schedule_date
      }
    }

    let(:return_booking) {
      {
        flight_number: return_flight.flight_number,
        source: destination_airport.city,
        destination: source_airport.city,
        class_type: seat_class.name.downcase,
        passengers: 2,
        departure_date: return_schedule_date
      }
    }

    let(:valid_params) { { bookings: [onward_booking, return_booking] } }

    it "books round trip successfully with valid data" do
      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to eq("Round trip booking successful🎉")
      expect(json["onward"]).to be_present
      expect(json["return"]).to be_present
    end

    it "fails when bookings param is not an array of two" do
      post "/api/round_trip_booking", params: { bookings: [onward_booking] }
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Both onward and return bookings must be provided")
    end

    it "fails when onward schedule is missing" do
      schedule.destroy
      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:not_found) 
      json = JSON.parse(response.body)  
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to start_with("Onward booking failed:")
    end

    it "fails and rolls back when return booking fails" do
      return_seat.update!(available_seats: 0)
      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:conflict) 
      json = JSON.parse(response.body)
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to start_with("Return booking failed:")
    end

    it "handles unexpected errors gracefully" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_raise(StandardError.new("unexpected crash"))
      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:internal_server_error)
      json = JSON.parse(response.body)
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Booking failed: unexpected crash")
    end

    it "handles return booking failure after transaction block" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_wrap_original do |original, *args|
        @calls ||= 0
        @calls += 1
        if @calls == 1
          { success: true, message: "Onward booked", data: {} }
        else
          { success: false, message: "Return failed", status: 422 }
        end
      end

      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Return booking failed: Return failed")
    end

    it "fails and returns from transaction if onward booking fails" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return(
        { success: false, message: "Onward failed", status: 422 }
      )

      post "/api/round_trip_booking", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to start_with("Onward booking failed:")
    end

    it "defaults to 1 passenger if 0 is given" do
      zero_passenger_booking = onward_booking.deep_dup
      zero_passenger_booking[:passengers] = 0

      post "/api/round_trip_booking", params: { bookings: [zero_passenger_booking, return_booking] }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
    end
  end
end
