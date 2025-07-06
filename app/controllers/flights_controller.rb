class FlightsController < ApplicationController
  DATA_PATH = Rails.root.join("data/data.txt")
  def index
  end

  def search
    @cities = [ "Bangalore", "Chennai", "Delhi", "Mumbai", "London", "New York" ]
    source = params[:source]
    destination = params[:destination]
    flights = read_flights
    @matching_flights = flights.select do |flight|
      flight[:source].casecmp?(source) &&
      flight[:destination].casecmp?(destination) &&
      flight[:total_seats].to_i > 0
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
end
