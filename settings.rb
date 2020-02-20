$settings = {
    :maxArmiesPerPlayer => 8,
    :farmMaxResourcesPerInterval => 10,
    :resourceTypes => [
        "wood",
        "ore",
        "clay",
        "wool",
        "grain"
    ],
    :buildingTypes => [
        "farm",
        "shrine"
    ],
    :buildings => {
      :farm => {
        :cost => [],
        :max => 5,
        :description => "Farms produce resources every 10 minutes.",
        :buildSeconds => 60 * 10,
        :maxResourcesPerInterval => 10
      },
      :shrine => {
        :cost => [
          {:type => "wood", :num => 5000},
          {:type => "ore", :num => 5000},
          {:type => "clay", :num => 5000},
          {:type => "wool", :num => 5000},
        ],
        :max => 5,
        :description => "A large structure for people to gather.  Build 5 to win the game.",
        :buildSeconds => 60 * 60 * 6
      }
    },
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
                {:type => "ore", :num => 1.0},
                {:type => "grain", :num => 0.1}
            ],
            :bonusAgainst => [],
            :attack => 6.0,
            :defense => 6.0,
            :speed => 8.0,
            :consumes => [
                {:type => "grain", :num => 0.05},
            ]
        },
        :archer => {
            :name => "Archer",
            :cost => [
                {:type => "wood", :num => 1.0},
                {:type => "grain", :num => 0.1}
            ],
            :bonusAgainst => [
                "footman",
                "pikeman"
            ],
            :attack => 3.0,
            :defense => 7.0,
            :speed => 8.0,
            :consumes => [
                {:type => "grain", :num => 0.05}
            ]
        },
        :pikeman => {
            :name => "Pikeman",
            :cost => [
                {:type => "clay", :num => 2.0},
                {:type => "grain", :num => 0.1}
            ],
            :bonusAgainst => [
                "knight"
            ],
            :attack => 1.0,
            :defense => 10.0,
            :speed => 5.0,
            :consumes => [
                {:type => "grain", :num => 0.05}
            ]
        },
        :knight => {
            :name => "Knight",
            :cost => [
                {:type => "ore", :num => 1.0},
                {:type => "wool", :num => 2.0},
                {:type => "grain", :num => 0.1}
            ],
            :bonusAgainst => [
                "footman",
                "archer"
            ],
            :attack => 10.0,
            :defense => 3.0,
            :speed => 20.0,
            :consumes => [
                {:type => "grain", :num => 0.05}
            ]
        },
        :catapult => {
            :name => "Catapult",
            :cost => [
                {:type => "wood", :num => 10.0},
                {:type => "grain", :num => 0.1}
            ],
            :bonusAgainst => [],
            :attack => 50.0,
            :defense => 0.0,
            :speed => 1.0,
            :consumes => [
                {:type => "wood", :num => 0.05}
            ]
        }
    },
    :perPage => 15,
    :marketIncrement => 0.00003,    # how much the market goes up or down
    :marketTax => 0.05,
    :battleBonusMultiplier => 2.0,
    :battleWinnings => 0.05,    # how much does winner of battle get from loser
    :armyTravelDistance => 200.0      # higher number makes army travel times longer
}
