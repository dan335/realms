require './attacks.rb'
require './settings.rb'


RSpec.describe "attacks" do
  it "gets number of soldiers" do
    army = {
      :footmen => 3,
      :archers => 5
    }
    getNumberOfSoldiers(army)

    expect(army[:numSoldiers]).to eq(8)
  end


  it "gets percentage" do
    army = {
      :footmen => 3,
      :archers => 5
    }

    getPercentage(army)

    expect(army[:percentage][:footman]).to eq(3.0/8.0)
    expect(army[:percentage][:archer]).to eq(5.0/8.0)
    expect(army[:percentage][:knight]).to eq(0.0)
  end
end
