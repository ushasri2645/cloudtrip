class DynamicPricingService
  def self.calculate_price(base_price, total_seats, available_seats, flight_date_str)
    strategies = [
      SeatBasedPricing.new,
      DateBasedPricing.new
    ]

    strategies.sum do |strategy|
      strategy.calculate(
        base_price: base_price,
        total_seats: total_seats,
        available_seats: available_seats,
        flight_date: flight_date_str
      )
    end
  end
end

class SeatBasedPricing
  def calculate(base_price:, total_seats:, available_seats:, **)
    seats_sold = total_seats - available_seats
    seat_ratio = seats_sold.to_f / total_seats

    seat_multiplier =
      if seat_ratio <= 0.3
        0.0
      elsif seat_ratio <= 0.5
        0.2
      elsif seat_ratio <= 0.75
        0.35
      else
        0.5
      end
    base_price * seat_multiplier
  end
end


class DateBasedPricing
  def calculate(base_price:, flight_date:, **)
    days_left = (flight_date - Time.zone.today).to_i
    if days_left <= 15 && days_left >= 3
      base_price * (0.02 * (15 - days_left))
    elsif days_left < 3 && days_left >= 0
      base_price * (0.15 * (3 - days_left))
    else
      0
    end
  end
end






