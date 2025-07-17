require 'rails_helper'

RSpec.describe Airport, type: :model do
  before do
    @airport = Airport.create(city: "Delhi", code: "DEL")
  end

  it "is valid with valid attributes" do
    expect(@airport).to be_valid
  end

  it "is not valid without city" do
    expect(Airport.new(code: "MAA")).not_to be_valid
  end

  it "is not valid without code" do
    expect(Airport.new(city: "Chennai")).not_to be_valid
  end

  after do
    Flight.delete_all
    Airport.delete_all
  end
end
