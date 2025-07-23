require 'rails_helper'

RSpec.describe "Api::BookingsController", type: :request do
  let(:valid_booking_params) do
    {
      flight: {
        flight_number: "123",
        class_type: "economy",
        source: "DEL",
        destination: "HYD",
        departure_date: "2025-08-01",
        departure_time: "10:00"
      },
      passengers: 2
    }
  end

  let(:headers) do
    { "ACCEPT" => "application/json" }
  end

  describe "POST /api/book" do
    it "returns success on valid one-way booking" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return({
        success: true,
        flight: "FlightObject",
        seat_class: "economy"
      })

      post "/api/book", params: valid_booking_params, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("updated" => true, "message" => "Booking successful")
    end

    it "returns error on failed one-way booking" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return({
        success: false,
        message: "Seat class not found"
      })

      post "/api/book", params: valid_booking_params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include("updated" => false, "error" => "Seat class not found")
    end
  end

  describe "POST /api/round_trip_booking" do
    let(:valid_round_trip_params) do
      {
        bookings: [
          {
            flight_number: "123",
            class_type: "economy",
            passengers: 2,
            source: "DEL",
            destination: "HYD",
            departure_date: "2025-08-01"
          },
          {
            flight_number: "456",
            class_type: "economy",
            passengers: 2,
            source: "HYD",
            destination: "DEL",
            departure_date: "2025-08-05"
          }
        ]
      }
    end

    it "returns success when both onward and return bookings succeed" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return({
        success: true,
        data: "BookingData"
      })

      post "/api/round_trip_booking", params: valid_round_trip_params, headers: headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to eq("Round trip booking successful")
    end

    it "returns error if onward booking fails" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_return({
        success: false,
        message: "Seat class not found",
        status: 422
      })

      post "/api/round_trip_booking", params: valid_round_trip_params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include("updated" => false, "error" => "Onward booking failed: Seat class not found")
    end

    it "returns error if return booking fails and onward is rolled back" do
      call_count = 0
      allow_any_instance_of(FlightBookingService).to receive(:book_flight) do
        call_count += 1
        if call_count == 1
        { success: true, data: "BookingData" }
        else
        { success: false, message: "Return booking failed", status: 409 }
        end
      end

      post "/api/round_trip_booking", params: valid_round_trip_params, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to include("updated" => false)
    end

    it "returns error if bookings param is missing or not an array" do
      post "/api/round_trip_booking", params: { bookings: "not_an_array" }, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include("updated" => false)
    end

    it "returns 500 internal error if exception is raised in transaction" do
      allow_any_instance_of(FlightBookingService).to receive(:book_flight).and_raise(StandardError.new("Simulated crash"))

      post "/api/round_trip_booking", params: valid_round_trip_params, headers: headers

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body).to include(
        "updated" => false,
        "error" => a_string_including("Booking failed: Simulated crash")
      )
    end

    it "defaults passengers to 1 if zero or negative is given (one-way)" do
      invalid_passenger_params = valid_booking_params.merge(passengers: -3)

      expect(FlightBookingService).to receive(:new).with(hash_including(passengers: 1)).and_return(
        instance_double(FlightBookingService, book_flight: {
          success: true,
          flight: "FlightObject",
          seat_class: "economy"
        })
      )

      post "/api/book", params: invalid_passenger_params, headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "defaults passengers to 1 in round trip booking if passengers is 0" do
      faulty_params = valid_round_trip_params.deep_dup

      faulty_params[:bookings][0][:passengers] = 0
      faulty_params[:bookings][1][:passengers] = 0

      instance1 = instance_double(FlightBookingService, book_flight: { success: true, data: "BookingData" })
      instance2 = instance_double(FlightBookingService, book_flight: { success: true, data: "ReturnBookingData" })

      expect(FlightBookingService).to receive(:new).with(hash_including(passengers: 1)).and_return(instance1).ordered
      expect(FlightBookingService).to receive(:new).with(hash_including(passengers: 1)).and_return(instance2).ordered

      post "/api/round_trip_booking", params: faulty_params, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
