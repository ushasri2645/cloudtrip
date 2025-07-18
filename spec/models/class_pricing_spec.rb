require 'rails_helper'

RSpec.describe ClassPricing, type: :model do
  it "is not valid without flight and seat_class" do
    expect(ClassPricing.new).not_to be_valid
  end

  it { should belong_to(:flight) }
  it { should belong_to(:seat_class) }

  it { should validate_presence_of(:multiplier) }

  after do
    ClassPricing.delete_all
  end
end
