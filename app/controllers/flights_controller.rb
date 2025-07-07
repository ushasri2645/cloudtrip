require_relative "../services/dynamic_pricing_service"

class FlightsController < ApplicationController
  DATA_PATH = Rails.configuration.flight_data_file

  def index; end

  def search
    source = params[:source]
    destination = params[:destination]
    date = params[:date]
    passengers = params[:passengers].to_i
    class_type = params[:class_type]
    flights = read_flights
    price_multiplier = 1.0
    @matching_flights = flights.select do |flight|
      seats_available, price_multiplier =
        case class_type
        when "economy"
            [ flight[:economy_seats], 1.0 ]
        when "business"
            [ flight[:business_seats], 1.5 ]
        when "first_class"
            [ flight[:first_class_seats], 2.0 ]
        end

      flight[:source].casecmp?(source) &&
      flight[:destination].casecmp?(destination) &&
      flight[:date] == date &&
      seats_available >= passengers
    end.map do |flight|
      seat_key = "#{class_type}_seats".to_sym
      available_seats = flight[seat_key]
      total_seats =
        case class_type
        when "economy"     then flight[:economy_total]
        when "business"    then flight[:business_total]
        when "first_class" then flight[:first_class_total]
        end

      dynamic_price = DynamicPricingService.calculate_price(
        flight[:price],
        total_seats,
        available_seats
      )

      price_per_person = (dynamic_price - flight[:price])  + (flight[:price] * price_multiplier)
      total_fare = price_per_person * passengers


      flight.merge(
        total_fare: total_fare,
        price_per_seat: dynamic_price,
        price_per_person: price_per_person
      )
    end

    flash.now[:alert] = "No Flights Available" if @matching_flights.empty?
    render :index
  end

  private

  def read_flights
    File.readlines(DATA_PATH).map do |line|
      fields = line.strip.split(",")
      {
        flight_number: fields[0],
        source: fields[1],
        destination: fields[2],
        date: fields[3],
        arrival_time: fields[4],
        departure_time: fields[5],
        total_seats: fields[6].to_i,
        price: fields[7].to_f,
        economy_seats: fields[8].to_i,
        business_seats: fields[9].to_i,
        first_class_seats: fields[10].to_i,
        economy_total: fields[11].to_i,
        business_total: fields[12].to_i,
        first_class_total: fields[13].to_i
      }
    end
  end
end
