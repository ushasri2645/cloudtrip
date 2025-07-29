require 'rails_helper'

RSpec.describe FlightSearchService do
  before(:all) do
    BaseFlightSeat.destroy_all
    Flight.destroy_all
    Airport.destroy_all
    SeatClass.destroy_all
    @economy_class = SeatClass.create!(name: "Economy")

    @source_airport = Airport.create!(city: "Hyderabad", code: "HYD")
    @destination_airport = Airport.create!(city: "Delhi", code: "DEL")

    @flight = Flight.create!(
      flight_number: "AI123",
      source: @source_airport,
      destination: @destination_airport,
      departure_time: 2.days.from_now.change(hour: 10),
      duration_minutes: 120,
      is_recurring: false,
    )

    @base_flight_seat=  BaseFlightSeat.create!(
        flight: @flight,
        seat_class: @economy_class,
        total_seats: 100,
        price: 3500
      )

    @flight_schedule =  FlightSchedule.create!(
        flight: @flight,
        flight_date: Time.zone.today
    )

    @flight_schedule_seat = FlightScheduleSeat.create!(
        flight_schedule: @flight_schedule,
        seat_class: @economy_class,
        available_seats: 80
    )
  end

  after(:all) do
    BaseFlightSeat.destroy_all
    Flight.destroy_all
    Airport.destroy_all
    SeatClass.destroy_all
  end

  describe "#search_flights" do
    context "when all inputs are valid" do
      it "returns available flights" do
        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 2)
        result = service.search_flights
        expect(result[:status]).to eq(200)
        expect(result[:flights]).not_to be_empty
        expect(result[:flights][0][:flight_number]).to eq("AI123")
        expect(result[:message]).to eq("Flights found")
      end
    end

    context "when invalid class type is provided" do
      it "returns error with 400" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 2.days.from_now, "Luxury", 2)
        result = service.search_flights

        expect(result[:status]).to eq(400)
        expect(result[:message]).to eq("Invalid class type")
      end
    end

    context "when source or destination city is not served" do
      it "returns error with 400" do
        service = FlightSearchService.new("UnknownCity", "Delhi", 2.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(400)
        expect(result[:message]).to eq("Source or destination not found.")
      end
    end

    context "when there are no flights between source and destination" do
      it "returns 404 error" do
        other_airport = Airport.create!(city: "Mumbai", code: "BOM")
        service = FlightSearchService.new("Mumbai", "Delhi", Time.zone.today, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(404)
        expect(result[:message]).to eq("We are not operating on this route. Sorry for the inconvenience")

        other_airport.destroy
      end
    end

    context "when there are no flights on the selected date" do
      it "returns 404 error" do
        service = FlightSearchService.new("Hyderabad", "Delhi", 5.days.from_now, "Economy", 2)
        result = service.search_flights

        expect(result[:status]).to eq(200)
        expect(result[:flights]).to eq([])
      end
    end

    context "when requesting more passengers than available seats" do
      it "returns 409 error" do
        @flight_schedule_seat.update!(available_seats: 0)

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 25)
        result = service.search_flights

        expect(result[:status]).to eq(409)
        expect(result[:message]).to include("All seats are booked")
      end
    end

    context "when flight schedule seat does not exist" do
      it "creates a new flight schedule seat with available seats from base" do
        FlightScheduleSeat.destroy_all

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
        result = service.search_flights

        seat = FlightScheduleSeat.find_by(flight_schedule: @flight_schedule, seat_class: @economy_class)
        expect(result[:status]).to eq(200)
        expect(seat).not_to be_nil
        expect(seat.available_seats).to eq(100)
      end
    end

    context "extended scenarios" do
      it "normalizes class type with casing and whitespace" do
      service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "  eCoNoMy  ", 2)
      result = service.search_flights

      expect(result[:status]).to eq(200)
      expect(result[:flights]).not_to be_empty
      end

      it "normalizes city names with whitespace and casing" do
        service = FlightSearchService.new("  hyDERabad  ", "  delhi ", Time.zone.today, "Economy", 1)
        result = service.search_flights

        expect(result[:status]).to eq(200)
        expect(result[:flights][0][:source]).to eq("Hyderabad")
      end

      it "calculates total fare correctly based on dynamic pricing" do
        allow(DynamicPricingService).to receive(:calculate_price).and_return(100)

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 2)
        result = service.search_flights

        expect(result[:flights][0][:price_per_seat]).to eq(100.0)
        expect(result[:flights][0][:total_fare]).to eq(7200.0)
      end

      it "returns multiple matching flights if present" do
        second_flight = Flight.create!(
          flight_number: "AI456",
          source: @source_airport,
          destination: @destination_airport,
          departure_time: 2.days.from_now.change(hour: 14),
          duration_minutes: 90,
          is_recurring: false,
        )
        BaseFlightSeat.create!(
          flight: second_flight,
          seat_class: @economy_class,
          total_seats: 50,
          price: 3000
        )
        schedule = FlightSchedule.create!(
          flight: second_flight,
          flight_date: Time.zone.today
        )
        FlightScheduleSeat.create!(
          flight_schedule: schedule,
          seat_class: @economy_class,
          available_seats: 30
        )

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
        result = service.search_flights

        expect(result[:flights].size).to eq(2)
        expect(result[:status]).to eq(200)
      end

      it "includes recurring flights when date matches recurrence" do
        recurrence = FlightRecurrence.create!(
          flight: @flight,
          days_of_week: [ Time.zone.today.wday ],
          start_date: 1.week.ago.to_date
        )

        @flight_schedule.destroy

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
        result = service.search_flights

        expect(result[:status]).to eq(200)
        expect(result[:flights]).not_to be_empty
      end
    end
    
    context "when flights exist but none support the requested class" do
      it "returns 404 with a class-not-available message" do
        SeatClass.create!(name: "Business") 

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Business", 1)
        result = service.search_flights

        expect(result[:status]).to eq(404)
        expect(result[:message]).to eq("Sorry! 😔 No flights available for Business.")
        expect(result[:flights]).to be_empty
      end
    end
    
    context "when base seat is missing for a valid flight" do
      it "does not include that flight in the results" do
        business_class = SeatClass.create!(name: "Business")

        flight = Flight.create!(
          flight_number: "123",
          source: @source_airport,
          destination: @destination_airport,
          departure_time: 2.days.from_now.change(hour: 15),
          duration_minutes: 150,
          is_recurring: false
        )

        BaseFlightSeat.where(flight: flight, seat_class: business_class).destroy_all

        FlightSchedule.create!(
          flight: flight,
          flight_date: Time.zone.today
        )

        service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Business", 1)
        result = service.search_flights

        expect(result[:flights]).to be_empty
        expect(result[:status]).to eq(404)
        expect(result[:message]).to match(/no flights available/i)
      end
    end

  end

  describe "#readable_days" do
    it "returns 'Everyday' when recurrence covers all days" do
      service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
      days = (0..6).to_a
      expect(service.send(:readable_days, days)).to eq("Everyday")
    end

    it "returns short day names when not all days are included" do
      service = FlightSearchService.new("Hyderabad", "Delhi", Time.zone.today, "Economy", 1)
      days = [0, 2, 4] 
      readable = service.send(:readable_days, days)
      expect(readable).to eq("S T T")
    end
  end

end
