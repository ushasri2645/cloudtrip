require 'rails_helper'

RSpec.describe SeatClass, type: :model do
  it "is valid with name" do
    expect(SeatClass.new(name: "Business")).to be_valid
  end

  it "is not valid without name" do
    expect(SeatClass.new).not_to be_valid
  end

  it { should have_many(:class_pricings) }
  it { should have_many(:flight_seats) }
end
