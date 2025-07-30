require 'rails_helper'

RSpec.describe "Bookings", type: :request do
  let!(:source_airport)      { Airport.create!(city: "Chennai", code: "MAA") }
  let!(:destination_airport) { Airport.create!(city: "Delhi", code: "DEL") }
  let!(:flight) do
    Flight.create!(
      flight_number: "AI101",
      source: source_airport,
      destination: destination_airport,
      departure_time: "10:00",
      is_recurring: false,
      duration_minutes: 180
    )
  end
  let!(:seat_class) { SeatClass.create!(name: "Economy") }

  let!(:flight_schedule) do
    FlightSchedule.create!(flight: flight, flight_date: Time.zone.today.to_s)
  end

  let!(:schedule_seat) do
    FlightScheduleSeat.create!(
      flight_schedule: flight_schedule,
      seat_class: seat_class,
      available_seats: 50
    )
  end

  describe "POST /api/book" do
    it "books a seat for a flight schedule" do
      post "/api/book", params: {
        flight: {
          flight_number: flight.flight_number,
          source: "Chennai",
          destination: "Delhi",
          departure_date: Time.zone.today,
          class_type: "Economy",
          passengers: 2
        }
      }

      expect(response).to have_http_status(:ok)
      expect(schedule_seat.reload.available_seats).to eq(48)
      expect(response.parsed_body).to include("updated" => true, "message" => "Booking successful")
    end

    it "returns error for missing required fields" do
      post "/api/book", params: {
        flight: {
          flight_number: nil,
          source: nil,
          destination: nil,
          departure_date: nil,
          class_type: nil,
          passengers: nil
        }
      }

      expect(response).to have_http_status(400)
      expect(response.parsed_body).to include("error" => /Missing required fields/)
    end

    it "returns error when insufficient seats" do
      schedule_seat.update!(available_seats: 1)

      post "/api/book", params: {
        flight: {
          flight_number: flight.flight_number,
          source: "Chennai",
          destination: "Delhi",
          departure_date: Time.zone.today,
          class_type: "Economy",
          passengers: 2
        }
      }

      expect(response).to have_http_status(409)
      expect(response.parsed_body).to include("error" => "Not enough seats")
    end

    it "returns error when flight not found" do
      post "/api/book", params: {
        flight: {
          flight_number: "INVALID",
          source: "Chennai",
          destination: "Delhi",
          departure_date: Time.zone.today,
          class_type: "Economy",
          passengers: 1
        }
      }

      expect(response).to have_http_status(404)
      expect(response.parsed_body).to include("error" => "Flight not found")
    end

    it "returns error when no schedule on date" do
      post "/api/book", params: {
        flight: {
          flight_number: flight.flight_number,
          source: "Chennai",
          destination: "Delhi",
          departure_date: Time.zone.today + 5.days,
          class_type: "Economy",
          passengers: 1
        }
      }

      expect(response).to have_http_status(404)
      expect(response.parsed_body).to include("error" => "No schedule available on this date")
    end

    it "returns error when seat class not found" do
      post "/api/book", params: {
        flight: {
          flight_number: flight.flight_number,
          source: "Chennai",
          destination: "Delhi",
          departure_date: Time.zone.today,
          class_type: "Business", # not created
          passengers: 1
        }
      }

      expect(response).to have_http_status(404)
      expect(response.parsed_body).to include("error" => "Seat class not found")
    end
  end

  describe "POST /api/round_trip_booking" do
    let!(:return_flight) do
      Flight.create!(
        flight_number: "AI102",
        source: destination_airport,
        destination: source_airport,
        departure_time: "17:00",
        is_recurring: false,
        duration_minutes: 180
      )
    end

    let!(:return_schedule) do
      FlightSchedule.create!(flight: return_flight, flight_date: Time.zone.today + 1)
    end

    let!(:return_seat) do
      FlightScheduleSeat.create!(
        flight_schedule: return_schedule,
        seat_class: seat_class,
        available_seats: 50
      )
    end

    it "books a round trip successfully" do
      post "/api/round_trip_booking", params: {
        bookings: [
          {
            flight_number: flight.flight_number,
            source: "Chennai",
            destination: "Delhi",
            departure_date: Time.zone.today,
            class_type: "Economy",
            passengers: 1
          },
          {
            flight_number: return_flight.flight_number,
            source: "Delhi",
            destination: "Chennai",
            departure_date: Time.zone.today + 1,
            class_type: "Economy",
            passengers: 1
          }
        ]
      }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["updated"]).to be true
      expect(json["message"]).to eq("Round trip booking successful 🎉")
    end

    it "returns error when one leg fails" do
      return_seat.update!(available_seats: 0)

      post "/api/round_trip_booking", params: {
        bookings: [
          {
            flight_number: flight.flight_number,
            source: "Chennai",
            destination: "Delhi",
            departure_date: Time.zone.today,
            class_type: "Economy",
            passengers: 1
          },
          {
            flight_number: return_flight.flight_number,
            source: "Delhi",
            destination: "Chennai",
            departure_date: Time.zone.today + 1,
            class_type: "Economy",
            passengers: 1
          }
        ]
      }

      expect(response).to have_http_status(409)
      expect(response.parsed_body).to include("error" => "Return booking failed. Entire booking rolled back.")
    end

    it "returns error when both bookings are not present" do
      post "/api/round_trip_booking", params: {
        bookings: [
          {
            flight_number: flight.flight_number,
            source: "Chennai",
            destination: "Delhi",
            departure_date: Time.zone.today,
            class_type: "Economy",
            passengers: 1
          }
        ]
      }

      expect(response).to have_http_status(400)
      expect(response.parsed_body).to include("error" => "Both onward and return bookings must be provided")
    end
  end
end
