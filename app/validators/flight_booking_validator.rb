class FlightBookingValidator
  attr_reader :errors, :params

  def initialize(params)
    @params = params
    @errors = []
  end

  def valid?
    validate_presence && validate_passenger_count
  end

  def flight_number    = params[:flight_number]
  def source           = params[:source]
  def destination      = params[:destination]
  def class_type       = params[:class_type]
  def date             = params[:date]
  def passengers       = params[:passengers].to_i

  private

  def validate_presence
    required_fields = %i[flight_number source destination date class_type passengers]
    missing = required_fields.select { |f| params[f].blank? }

    if missing.any?
      add_error("Missing required fields: #{missing.join(', ')}", 400)
      return false
    end
    true
  end

  def validate_passenger_count
    return true if passengers.positive?

    add_error("Passenger count must be at least 1", 400)
    false
  end

  def add_error(message, status)
    errors << { message: message, status: status }
  end
end
