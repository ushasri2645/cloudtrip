require 'rails_helper'

RSpec.describe "Api::Bookings", type: :request do
  before(:each) do
    @source_airport = Airport.create!(city: "Delhi", code: "DEL")
    @destination_airport = Airport.create!(city: "Mumbai", code: "BOM")

    @flight = Flight.create!(
      flight_number: "OQ803",
      source: @source_airport,
      destination: @destination_airport,
      departure_datetime: DateTime.parse("2024-08-25T09:00:00+05:30"),
      arrival_datetime: DateTime.parse("2024-08-25T11:00:00+05:30"),
      total_seats: 170,
      price: 4500
    )

    @seat_class = SeatClass.create!(name: "Economy")

    @flight_seat = FlightSeat.create!(
      flight: @flight,
      seat_class: @seat_class,
      total_seats: 100,
      available_seats: 50
    )
  end

  after(:all) do
    FlightSeat.delete_all
    Flight.delete_all
    SeatClass.delete_all
    Airport.delete_all
  end

  describe "POST /api/book" do
    let(:base_flight_params) do
    {
      flight_number: @flight.flight_number,
      class_type: @seat_class.name,
      source: @flight.source.city,
      destination: @flight.destination.city,
      departure_date: @flight.departure_datetime.to_date.to_s,
      departure_time: @flight.departure_datetime.strftime("%H:%M")
    }
  end

    it "books successfully with valid params" do
      post "/api/book", params: {
        flight: base_flight_params,
        passengers: 2
      }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to include("Booking successful for 2 passengers")
    end

    it "returns error when flight_number is missing" do
      post "/api/book", params: {
        flight: base_flight_params.except(:flight_number),
        passengers: 1
      }

      expect(response).to have_http_status(:bad_request)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Missing flight_number parameter")
    end

    it "returns error when flight is not found" do
      post "/api/book", params: {
        flight: base_flight_params.merge(flight_number: "INVALID123"),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when seat class is invalid" do
      post "/api/book", params: {
        flight: base_flight_params.merge(class_type: "FirstClass"),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Seat class 'FirstClass' not found")
    end

    it "returns error when seat info is missing for flight class" do
      another_flight = Flight.create!(
        flight_number: "AB456",
        source: @source_airport,
        destination: @destination_airport,
        departure_datetime: DateTime.parse("2024-08-25T13:00:00+05:30"),
        arrival_datetime: DateTime.parse("2024-08-25T15:00:00+05:30"),
        total_seats: 150,
        price: 4000
      )

      post "/api/book", params: {
        flight: {
          flight_number: another_flight.flight_number,
          class_type: "Economy",
          source: another_flight.source.city,
          destination: another_flight.destination.city,
          departure_date: another_flight.departure_datetime.to_date.to_s,
          departure_time: another_flight.departure_datetime.strftime("%H:%M")
      },
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Seat info not available for Economy")

      another_flight.destroy
    end

    it "returns error when not enough seats are available" do
      @flight_seat.update!(available_seats: 1)

      post "/api/book", params: {
        flight: base_flight_params,
        passengers: 2
      }

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to include("Not enough seats in Economy")
    end

    it "handles unexpected error" do
      allow_any_instance_of(FlightSeat).to receive(:lock!).and_raise(StandardError.new("DB locked"))

      post "/api/book", params: {
        flight: base_flight_params,
        passengers: 1
      }

      expect(response).to have_http_status(:internal_server_error)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to include("Unexpected error: DB locked")
    end

    it "returns error when departure_date is missing" do
      post "/api/book", params: {
        flight: base_flight_params.except(:departure_date),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when departure_time is missing" do
      post "/api/book", params: {
        flight: base_flight_params.except(:departure_time),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when departure_date is invalid format" do
      post "/api/book", params: {
        flight: base_flight_params.merge(departure_date: "invalid-date"),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when departure_time is invalid format" do
      post "/api/book", params: {
        flight: base_flight_params.merge(departure_time: "25:61"),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when source city is invalid or not found" do
      post "/api/book", params: {
        flight: base_flight_params.merge(source: "Atlantis", departure_time: @flight.departure_datetime.strftime("%H:%M")),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when destination city is invalid or not found" do
      post "/api/book", params: {
        flight: base_flight_params.merge(destination: "El Dorado", departure_time: @flight.departure_datetime.strftime("%H:%M")),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "returns error when both source and destination cities are invalid" do
      post "/api/book", params: {
        flight: base_flight_params.merge(source: "Nowhere", destination: "Neverland", departure_time: @flight.departure_datetime.strftime("%H:%M")),
        passengers: 1
      }

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json["updated"]).to eq(false)
      expect(json["error"]).to eq("Requested flight not found")
    end

    it "defaults to 1 passenger if passengers param is zero or negative" do
      post "/api/book", params: {
        flight: base_flight_params,
        passengers: 0
      }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to eq(true)
      expect(json["message"]).to include("Booking successful for 1 passenger")
    end
  end
end
