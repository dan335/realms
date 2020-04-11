$settings = {
    :maxArmiesPerPlayer => 8,
    :farmMaxResourcesPerInterval => 10,
    :winningsSoldierCanCarry => 10.0,    # amount in gold that a soldier can carry
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
        :buildSeconds => 60 * 60 * 12
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
            :shortName => "footman",
            :cost => [
                {:type => "ore", :num => 2.0},
                {:type => "grain", :num => 0.2}
            ],
            :bonusAgainst => [
                "pikeman"
            ],
            :attack => 6.0,
            :defense => 6.0,
            :speed => 8.0,
            :consumes => [
                {:type => "grain", :num => 0.1},
            ]
        },
        :archer => {
            :name => "Archer",
            :shortName => "archer",
            :cost => [
                {:type => "wood", :num => 2.0},
                {:type => "grain", :num => 0.2}
            ],
            :bonusAgainst => [
                "footman",
                "pikeman"
            ],
            :attack => 2.0,
            :defense => 7.0,
            :speed => 8.0,
            :consumes => [
                {:type => "grain", :num => 0.1}
            ]
        },
        :pikeman => {
            :name => "Pikeman",
            :shortName => "pike",
            :cost => [
                {:type => "clay", :num => 4.0},
                {:type => "grain", :num => 0.2}
            ],
            :bonusAgainst => [
                "knight"
            ],
            :attack => 1.0,
            :defense => 10.0,
            :speed => 5.0,
            :consumes => [
                {:type => "grain", :num => 0.1}
            ]
        },
        :knight => {
            :name => "Knight",
            :shortName => "knight",
            :cost => [
                {:type => "ore", :num => 2.0},
                {:type => "wool", :num => 4.0},
                {:type => "grain", :num => 0.2}
            ],
            :bonusAgainst => [
                "footman",
                "archer"
            ],
            :attack => 10.0,
            :defense => 3.0,
            :speed => 20.0,
            :consumes => [
                {:type => "grain", :num => 0.1}
            ]
        },
        :catapult => {
            :name => "Catapult",
            :shortName => "cat",
            :cost => [
                {:type => "wood", :num => 10.0},
                {:type => "ore", :num => 10.0},
                {:type => "grain", :num => 0.2}
            ],
            :bonusAgainst => [],
            :attack => 50.0,
            :defense => 0.0,
            :speed => 1.2,
            :consumes => [
                {:type => "wood", :num => 0.1}
            ]
        }
    },
    :perPage => 15,
    :marketIncrement => 0.000038,    # how much the market goes up or down
    :marketTax => 0.25,
    :battleBonusMultiplier => 2.0,
    :battleWinnings => 0.1,    # max that winner of battle gets from loser
    :armyTravelDistance => 200.0,      # higher number makes army travel times longer
    :medianTaxRate => 0.75,     # rate at which happiness from taxes stays the same
    :startingPopulation => 100,
    :spendingPerPerson => 0.06,  # each person spends this much per interval then this is taxed,  higher increases tax collected from population
    :populationMaxGrowth => 20,
    :populationMaxGrowthFromReputation => 40,
    :maxReputationPercentage => 0.5,
    :losingBattleAffectsHappinessFor => 60 * 60 * 4,
    :winningBattleAffectsReputationFor => 60 * 60 * 4,
    :starvingSoldierDeathRate => 0.03
}
