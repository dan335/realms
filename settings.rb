$settings = {
    :maxFarms => 5,
    :farmBuildSeconds => 60*10,
    :farmMaxResourcesPerInterval => 10,
    :resourceTypes => [
        "wood",
        "ore",
        "clay",
        "wool"
    ],
    :soldierTypes => [
        "footman",
        "archer",
        "knight",
        "pikeman",
        "catapult"
    ],
    :soldiers => {
        :footman => {
            :name => "Footman",
            :cost => [
                {:type => "ore", :num => 1}
            ],
            :bonusAgainst => [],
            :attack => 5,
            :defense => 5,
            :speed => 5
        },
        :archer => {
            :name => "Archer",
            :cost => [
                {:type => "wood", :num => 1}
            ],
            :bonusAgainst => [
                "footman",
                "pikeman"
            ],
            :attack => 3,
            :defense => 7,
            :speed => 5
        },
        :pikeman => {
            :name => "Pikeman",
            :cost => [
                {:type => "clay", :num => 2}
            ],
            :bonusAgainst => [
                "knight"
            ],
            :attack => 1,
            :defense => 10,
            :speed => 3
        },
        :knight => {
            :name => "Knight",
            :cost => [
                {:type => "ore", :num => 1},
                {:type => "wool", :num => 2}
            ],
            :bonusAgainst => [
                "footman",
                "archer"
            ],
            :attack => 10,
            :defense => 3,
            :speed => 20
        },
        :catapult => {
            :name => "Catapult",
            :cost => [
                {:type => "wood", :num => 10}
            ],
            :bonusAgainst => [],
            :attack => 50,
            :defense => 0,
            :speed => 1
        }
    },
    :perPage => 15,
    :marketIncrement => 0.00001,    # how much the market goes up or down
    :marketTax => 0.05,
    :armyTravelDistance => 200.0      # higher number makes army travel times longer
}