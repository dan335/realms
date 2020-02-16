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


  it "gets power" do
    army = {
      :footmen => 3,
      :archers => 5
    }

    getPower(army, true)
    expect(army[:totalPower]).to eq(30.0)
    expect(army[:power][:footman]).to eq(15.0)
    expect(army[:power][:archer]).to eq(15.0)
    expect(army[:power][:knight]).to eq(0.0)

    getPower(army, false)
    expect(army[:totalPower]).to eq(50.0)
    expect(army[:power][:footman]).to eq(15.0)
    expect(army[:power][:archer]).to eq(35.0)
    expect(army[:power][:knight]).to eq(0.0)
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

  it "gets bonus" do
    attackingArmy = {
      :footmen => 3,
      :archers => 5,
      :pikemen => 2
    }

    defendingArmy = {
      :knights => 3
    }

    getPercentage(attackingArmy)
    getPercentage(defendingArmy)

    getBonus(attackingArmy, defendingArmy)

    expect(attackingArmy[:totalBonus]).to eq(3.0)
    expect(attackingArmy[:bonus][:footman]).to eq(0.0)
    expect(attackingArmy[:bonus][:archer]).to eq(0.0)
    expect(attackingArmy[:bonus][:pikeman]).to eq(3.0)
    expect(attackingArmy[:bonus][:knight]).to eq(0.0)

    expect(defendingArmy[:totalBonus]).to eq(3.5999999999999996)
    expect(defendingArmy[:bonus][:footman]).to eq(0.0)
    expect(defendingArmy[:bonus][:archer]).to eq(0.0)
    expect(defendingArmy[:bonus][:pikeman]).to eq(0.0)
    expect(defendingArmy[:bonus][:knight]).to eq(3.5999999999999996)
  end


  it "gets final power" do
    attackingArmy = {
      :footmen => 3,
      :archers => 5,
      :pikemen => 2
    }

    defendingArmy = {
      :knights => 3
    }

    getPercentage(attackingArmy)
    getPercentage(defendingArmy)
    getPower(attackingArmy, true)
    getPower(defendingArmy, false)
    getBonus(attackingArmy, defendingArmy)
    getFinalPower(attackingArmy)
    getFinalPower(defendingArmy)

    expect(attackingArmy[:finalPower]).to eq(35.0)
    expect(attackingArmy[:finalPowerPerSoldier][:footman]).to eq(5.0)
    expect(attackingArmy[:finalPowerPerSoldier][:archer]).to eq(3.0)
    expect(attackingArmy[:finalPowerPerSoldier][:pikeman]).to eq(2.5)
    expect(attackingArmy[:finalPowerPerSoldier][:knight]).to eq(0.0)

    expect(defendingArmy[:finalPower]).to eq(12.6)
    expect(defendingArmy[:finalPowerPerSoldier][:footman]).to eq(0.0)
    expect(defendingArmy[:finalPowerPerSoldier][:archer]).to eq(0.0)
    expect(defendingArmy[:finalPowerPerSoldier][:pikeman]).to eq(0.0)
    expect(defendingArmy[:finalPowerPerSoldier][:knight]).to eq(4.2)
  end

  it "gets winner" do
    attackingArmy = {
      :footmen => 3,
      :archers => 5,
      :pikemen => 2
    }

    defendingArmy = {
      :knights => 3
    }

    getPercentage(attackingArmy)
    getPercentage(defendingArmy)
    getPower(attackingArmy, true)
    getPower(defendingArmy, false)
    getBonus(attackingArmy, defendingArmy)
    getFinalPower(attackingArmy)
    getFinalPower(defendingArmy)

    getWinner(attackingArmy, defendingArmy)

    expect(attackingArmy[:isWinner]).to eq(true)
    expect(defendingArmy[:isWinner]).to eq(false)
  end

  it "gets power to lose" do
    attackingArmy = {
      :footmen => 3,
      :archers => 5,
      :pikemen => 2
    }

    defendingArmy = {
      :knights => 3
    }

    getPercentage(attackingArmy)
    getPercentage(defendingArmy)
    getPower(attackingArmy, true)
    getPower(defendingArmy, false)
    getBonus(attackingArmy, defendingArmy)
    getFinalPower(attackingArmy)
    getFinalPower(defendingArmy)
    getWinner(attackingArmy, defendingArmy)
    getPowerToLose(attackingArmy, defendingArmy)

    expect(attackingArmy[:powerToLose]).to eq(5.04)
    expect(defendingArmy[:powerToLose]).to eq(500.0952)
  end


  it "gets loses" do
    attackingArmy = {
      :footmen => 3,
      :archers => 5,
      :pikemen => 2
    }

    defendingArmy = {
      :knights => 3
    }

    getNumberOfSoldiers(attackingArmy)
    getNumberOfSoldiers(defendingArmy)
    getPercentage(attackingArmy)
    getPercentage(defendingArmy)
    getPower(attackingArmy, true)
    getPower(defendingArmy, false)
    getBonus(attackingArmy, defendingArmy)
    getFinalPower(attackingArmy)
    getFinalPower(defendingArmy)
    getWinner(attackingArmy, defendingArmy)
    getPowerToLose(attackingArmy, defendingArmy)
    getLoses(attackingArmy)
    getLoses(defendingArmy)

    expect(attackingArmy[:numLoses]).to eq(1)

    expect(defendingArmy[:numLoses]).to eq(3)
    expect(defendingArmy[:loses][:knight]).to eq(3)
    expect(defendingArmy[:loses][:footman]).to eq(0)
  end
end
