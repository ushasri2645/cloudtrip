require 'rails_helper'

describe DynamicPricingService do
  describe '.calculate_price' do
    let(:base_price) { 1000 }
    let(:total_seats) { 100 }

    context 'when 50% seats are sold and flight is in 10 days' do
      it 'calculates seat-based and date-based dynamic prices correctly' do
        available_seats = 50
        flight_date = Time.zone.today + 10.days

        price = DynamicPricingService.calculate_price(
          base_price,
          total_seats,
          available_seats,
          flight_date
        )
        expect(price).to eq(300)
      end
    end

    context 'when all seats are available and flight is in 20 days' do
      it 'returns 0 dynamic pricing' do
        available_seats = 100
        flight_date = Time.zone.today + 20.days

        price = DynamicPricingService.calculate_price(
          base_price,
          total_seats,
          available_seats,
          flight_date
        )

        expect(price).to eq(0)
      end
    end

    context 'when seats are 75% sold and flight is in 1 day' do
      it 'calculates high dynamic pricing' do
        available_seats = 25
        flight_date = Time.zone.today + 1.day

        price = DynamicPricingService.calculate_price(
          base_price,
          total_seats,
          available_seats,
          flight_date
        )
        expect(price).to eq(650)
      end
    end
    context 'when more than 75% seats are sold' do
      it 'applies 50% seat multiplier' do
        available_seats = 20
        flight_date = Time.zone.today + 20.days

        price = DynamicPricingService.calculate_price(
          base_price,
          total_seats,
          available_seats,
          flight_date
        )
        expect(price).to eq(500)
      end
    end
    context 'when flight is after 20 days' do
      it 'does not apply any date-based pricing' do
        available_seats = 100
        flight_date = Time.zone.today + 20.days

        price = DynamicPricingService.calculate_price(
          base_price,
          total_seats,
          available_seats,
          flight_date
        )

        expect(price).to eq(0)
      end
    end
  end
end
