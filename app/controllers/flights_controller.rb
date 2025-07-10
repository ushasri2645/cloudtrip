require_relative "../services/dynamic_pricing_service"

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

    if source.blank? || destination.blank? || date.blank?
      flash.now[:alert] = "Please enter Source, Destination, and Date."
      @matching_flights = []
      return render :index
    end

    passengers = params[:passengers].present? ? params[:passengers].to_i : 1
    if params[:class_type].blank?
      class_type = "economy"
      flash.now[:alert] = "Class type not selected. Defaulting to Economy class."
    else
      class_type = params[:class_type]
    end

    if source.present? && destination.present? && source.casecmp?(destination)
      flash.now[:alert] = "Source and Destination must be different."
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
              [ flight[:economy_seats], 1.0 ]
        end

        time_condition = true

        if Date.parse(date) == Time.zone.today
          now = Time.zone.now
          flight_datetime_str = "#{flight[:departure_date]} #{flight[:departure_time]}"
          flight_time = Time.strptime(flight_datetime_str, "%Y-%m-%d %I:%M %p")
          time_condition = flight_time > now
        end

      flight[:source].casecmp?(source) &&
      flight[:destination].casecmp?(destination) &&
      flight[:departure_date] == date &&
      seats_available >= passengers &&
      time_condition
    end.map do |flight|
      seat_key = "#{class_type}_seats".to_sym
      available_seats = flight[seat_key]
      total_seats =
        case class_type
        when "economy"     then flight[:economy_total]
        when "business"    then flight[:business_total]
        when "first_class" then flight[:first_class_total]
        else flight[:economy_total]
        end

      dynamic_price = DynamicPricingService.calculate_price(
        flight[:price],
        total_seats,
        available_seats,
        flight[:departure_date]
      )

      price_per_person = (dynamic_price) + (flight[:price] * price_multiplier)
      total_fare = price_per_person * passengers

      flight.merge(
        total_fare: total_fare,
        price_per_seat: dynamic_price,
        price_per_person: price_per_person,
        class_type: class_type || "economy"
      )
    end

    flash.now[:alert] = "No Flights Available" if @matching_flights.empty?
    render :index
  end

  def book
    flight_number = params[:flight_number]
    class_type    = params[:class_type] || 'economy'
    passengers    = params["passengers"].present? ? params[:passengers].to_i : 1

    lines = File.readlines(DATA_PATH)
    updated_lines = []
    updated = false
    lines.each do |line|
      fields = line.strip.split(",")
      if fields[0] == flight_number
        seat_index = case class_type
        when "economy"     then 9
        when "business"    then 10
        when "first_class" then 11
        end
        available_seats = fields[seat_index].to_i
        if available_seats >= passengers
          fields[seat_index] = (available_seats - passengers).to_s
          flash[:notice] = "Booking successful! ✅"
        else
          flash[:alert] = "Not enough seats available."
        end
        updated = true
      end
      updated_lines << fields.join(",")
    end
    if updated
      File.open(DATA_PATH, "w") do |file|
      file.puts updated_lines
      end
    end
    sleep 5
    redirect_to root_path
  end

  private
  def read_flights
    File.readlines(DATA_PATH).map do |line|
      fields = line.strip.split(",")
      {
        flight_number: fields[0],
        source: fields[1],
        destination: fields[2],
        departure_date: fields[3],
        departure_time: fields[4],
        arrival_date: fields[5],
        arrival_time: fields[6],
        total_seats: fields[7].to_i,
        price: fields[8].to_f,
        economy_seats: fields[9].to_i,
        business_seats: fields[10].to_i,
        first_class_seats: fields[11].to_i,
        economy_total: fields[12].to_i,
        business_total: fields[13].to_i,
        first_class_total: fields[14].to_i
      }
    end
  end

  def load_unique_cities
    read_flights.flat_map { |f| [ f[:source], f[:destination] ] }.uniq.sort
  end
end
