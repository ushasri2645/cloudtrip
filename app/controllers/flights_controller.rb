class FlightsController < ApplicationController
  DATA_PATH = Rails.configuration.flight_data_file
  def index
    @cities = load_unique_cities
  end

  def search
    @cities = load_unique_cities

    source = params[:source]
    destination = params[:destination]
    date = params[:date]
    passengers = params[:passengers].to_i
    class_type = params[:class_type]

    @destination_options = @cities.reject { |city| city.casecmp?(source.to_s) }

    if source.present? && destination.present? && source.casecmp?(destination)
    flash.now[:alert] = "Origin and Destination must be different."
    @matching_flights = []
    return render :index
    end

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
        else
            [ 0, 1.0 ]
        end

      flight[:source].casecmp?(source) &&
      flight[:destination].casecmp?(destination) &&
      flight[:date] == date &&
      seats_available >= passengers
    end
    .map do |flight|
        total_fare = flight[:price] * price_multiplier * passengers
        flight.merge(total_fare: total_fare)
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
        first_class_seats: fields[10].to_i
      }
    end
  end

  def load_unique_cities
    read_flights.flat_map { |f| [ f[:source], f[:destination] ] }.uniq.sort
  end
end
