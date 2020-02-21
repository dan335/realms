require './attacks.rb'
require './settings.rb'


RSpec.describe "attacks" do

  # market prices
  markets = []
  $settings[:resourceTypes].each do |resourceType|
    markets << {
      :type => resourceType,
      :value => 10.0
    }
  end



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



  it "gets correct winnings for 1 soldier" do
    attackingArmy = {
      :footmen => 1,
      :numSoldiers => 1,
      :numLoses => 0,
      :isWinner => true
    }

    defendingArmy = {
      :footmen => 0,
      :gold => 10000.0
    }

    winnings = getWinnings(attackingArmy, defendingArmy, markets)
    expect(winnings[:gold]).to eq($settings[:winningsSoldierCanCarry])
  end



  it "gets correct winnings for 10 soldier" do
    attackingArmy = {
      :footmen => 10,
      :numSoldiers => 10,
      :numLoses => 0,
      :isWinner => true
    }

    defendingArmy = {
      :footmen => 0,
      :gold => 10000.0
    }

    winnings = getWinnings(attackingArmy, defendingArmy, markets)
    expect(winnings[:gold]).to eq($settings[:winningsSoldierCanCarry] * attackingArmy[:footmen])
  end



  it "gets correct winnings for max $settings[:battleWinnings]" do
    attackingArmy = {
      :footmen => 10,
      :numSoldiers => 10,
      :numLoses => 0,
      :isWinner => true
    }

    defendingArmy = {
      :footmen => 0,
      :gold => 100.0
    }

    winnings = getWinnings(attackingArmy, defendingArmy, markets)
    expect(winnings[:gold]).to eq(defendingArmy[:gold] * $settings[:battleWinnings])
  end
end
