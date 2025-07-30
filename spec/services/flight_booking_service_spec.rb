require 'rails_helper'

RSpec.describe FlightBookingService do
  let(:validator) do
    double(
      source: "Mumbai",
      destination: "Delhi",
      flight_number: "AI101",
      class_type: "ECONOMY",
      passengers: 2,
      date: Time.zone.today
    )
  end

  let(:source_airport) { instance_double(Airport, id: 1) }
  let(:destination_airport) { instance_double(Airport, id: 2) }

  let(:flight) { instance_double(Flight, id: 1, flight_schedules: flight_schedule_relation) }
  let(:flight_schedule_relation) { double("FlightScheduleRelation", find_by: schedule) }

  let(:schedule) { instance_double(FlightSchedule, id: 1) }

  let(:seat_class) { instance_double(SeatClass, id: 1) }

  let(:seat) do
    instance_double(FlightScheduleSeat,
      id: 1,
      available_seats: 10,
      flight_schedule_id: schedule.id,
      seat_class_id: seat_class.id
    )
  end

  subject(:service) { described_class.new(validator) }

  before do
    allow(Airport).to receive(:find_by).with("LOWER(city) = ?", "mumbai").and_return(source_airport)
    allow(Airport).to receive(:find_by).with("LOWER(city) = ?", "delhi").and_return(destination_airport)

    allow(Flight).to receive(:find_by).with(
      flight_number: "AI101",
      source: source_airport,
      destination: destination_airport
    ).and_return(flight)

    allow(SeatClass).to receive(:find_by).with("LOWER(name) = ?", "economy").and_return(seat_class)

    allow(FlightScheduleSeat).to receive(:find_by).with(
      flight_schedule_id: schedule.id,
      seat_class_id: seat_class.id
    ).and_return(seat)

    allow(seat).to receive(:with_lock).and_yield
    allow(seat).to receive(:update!).and_return(true)
  end

  describe "#book" do
    context "when booking is successful" do
      it "returns success response with seat info" do
        result = service.book

        expect(result[:success]).to be true
        expect(result[:message]).to eq("Booking successful")
        expect(result[:status]).to eq(200)
        expect(result[:data]).to eq(seat)
      end
    end

    context "when flight is not found" do
      before do
        allow(Flight).to receive(:find_by).and_return(nil)
      end

      it "returns flight not found error" do
        result = service.book
        expect(result).to eq({ success: false, message: "Flight not found", status: 404 })
      end
    end

    context "when schedule not found" do
      before do
        allow(flight_schedule_relation).to receive(:find_by).and_return(nil)
      end

      it "returns schedule error" do
        result = service.book
        expect(result).to eq({ success: false, message: "No schedule available on this date", status: 404 })
      end
    end

    context "when seat class not found" do
      before do
        allow(SeatClass).to receive(:find_by).and_return(nil)
      end

      it "returns seat class error" do
        result = service.book
        expect(result).to eq({ success: false, message: "Seat class not found", status: 404 })
      end
    end

    context "when seat info not found" do
      before do
        allow(FlightScheduleSeat).to receive(:find_by).and_return(nil)
      end

      it "returns seat info error" do
        result = service.book
        expect(result).to eq({ success: false, message: "No seat info for this class on the selected date", status: 404 })
      end
    end

    context "when not enough seats available" do
      before do
        allow(seat).to receive(:available_seats).and_return(1)
      end

      it "returns not enough seats error" do
        result = service.book
        expect(result).to eq({ success: false, message: "Not enough seats", status: 409 })
      end
    end

    context "when update fails with exception" do
      before do
        allow(seat).to receive(:update!).and_raise(ActiveRecord::ActiveRecordError, "update failed")
      end

      it "returns booking failed error" do
        result = service.book
        expect(result[:success]).to be false
        expect(result[:message]).to include("Booking failed: update failed")
        expect(result[:status]).to eq(500)
      end
    end
  end
end
