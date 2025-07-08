require "rails_helper"

RSpec.describe DynamicPricingService do
  describe ".calculate_price" do
    let(:base_price) { 1000.0 }
    let(:today) { Time.zone.today }

    context "when 0–30% seats sold and flight is 20 days away" do
      it "returns base price (no increase)" do
        price = described_class.calculate_price(base_price, 100, 100, (today + 20).to_s)
        expect(price).to eq(0.0)
      end
    end

    context "when 40% seats sold and 7 days left" do
      it "adds 20% seat-based and 16% date-based increase" do
        seat = base_price * 0.2
        date = base_price * 0.16
        expected_price = seat + date
        price = described_class.calculate_price(base_price, 100, 60, (today + 7).to_s)
        expect(price).to eq(expected_price)
      end
    end

    context "when 75% seats sold and 2 days left" do
      it "adds 35% seat-based and 10% date-based increase per day (2 days)" do
        seat = base_price * 0.35
        date = base_price * 0.10
        expected_price = seat + date
        price = described_class.calculate_price(base_price, 100, 25, (today + 2).to_s)
        expect(price).to eq(expected_price)
      end
    end

    context "when 90% seats sold and flight is tomorrow" do
      it "adds 50% seat-based and 20% date-based increase" do
        seat = base_price * 0.5
        date = base_price * 0.2
        expected_price = seat + date
        price = described_class.calculate_price(base_price, 100, 10, (today + 1).to_s)
        expect(price).to eq(expected_price)
      end
    end

    context "when invalid date string is passed" do
      it "returns only seat-based price" do
        seat = base_price * 0.5
        price = described_class.calculate_price(base_price, 100, 20, "invalid-date")
        expect(price).to eq(seat)
      end
    end

    context "when no seats sold and flight is in 3 days" do
      it "returns only date-based increase" do
        seat = 0.0
        date = base_price * 0.10
        expected_price = seat + date
        price = described_class.calculate_price(base_price, 100, 100, (today + 2).to_s)
        expect(price).to eq(expected_price)
      end
    end
  end
end
