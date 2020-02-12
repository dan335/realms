require './commonFunctions.rb'


def doAttack(mongo, army)

    # get defender
    otherUser = mongo[:users].find(:_id => army[:otherUserId]).first

    # get attacking soldiers
    soldiers = {}
    army[:soldiers].each do |s|
        soldiers[s[:type].pluralize.to_sym] = s[:num]
    end

    # calculate attack
    processAttack(soldiers, otherUser)
    puts "----"
    puts soldiers
    puts "----"
    puts otherUser
    puts "----"

    # get winnings
    winnings = {:gold => 0} # for winner
    inc = {:gold => 0}  # for loser

    if soldiers[:isWinner] && soldiers[:numLoses] < soldiers[:numSoldiers]
        winnings[:gold] = otherUser[:gold] * $settings[:battleWinnings]
        inc[:gold] = winnings[:gold] * -1.0
    end

    $settings[:resourceTypes].each do |resourceType|
        if soldiers[:isWinner] && soldiers[:numLoses] < soldiers[:numSoldiers]
            winnings[resourceType.to_sym] = (otherUser[resourceType.to_sym].to_f * $settings[:battleWinnings]).floor
            inc[resourceType.to_sym] = winnings[resourceType.to_sym] * -1
        else
            winnings[resourceType.to_sym] = 0
            inc[resourceType.to_sym] = 0
        end
    end

    # save otherUser
    set = {}
    $settings[:soldierTypes].each do |soldierType|
        set[soldierType.pluralize.to_sym] = otherUser[soldierType.pluralize.to_sym].to_i
    end
    mongo[:users].update_one({_id: otherUser[:_id]}, {"$set": set, "$inc": inc})
    updateNetworthFor(mongo, otherUser[:discordId])

    # check if army is dead
    if soldiers[:numLoses] == soldiers[:numSoldiers]
        return
    end

    # put soldiers back into army
    army[:soldiers].map do |s|
        s[:num] = soldiers[s[:type].pluralize.to_sym].to_i - soldiers[:loses][s[:type]].to_i
    end

    # get army travel time
    slowest = 99999
    army[:soldiers].each do |soldier|
        s = $settings[:soldiers][soldier[:type].to_sym][:speed]
        if s < slowest
            slowest = s
        end
    end
    durationSeconds = $settings[:armyTravelDistance] / slowest.to_f * 60.0

    # create returning army
    mongo[:armies].insert_one({
        :discordId => army[:discordId],
        :userId => army[:userId],
        :createdAt => Time.now,
        :arriveAt => Time.now + durationSeconds,
        :soldiers => army[:soldiers],
        :isAttacking => false,    # false if army is returning from battle
        :winnings => winnings
    })
end


def returnToRealm(mongo, army)

    # add army back to user
    inc = {}
    army[:soldiers].each do |s|
        inc[s[:type].pluralize.to_sym] = s[:num]
    end
    
    inc[:gold] = army[:winnings][:gold]

    $settings[:resourceTypes].each do |resourceType|
        inc[resourceType.to_sym] = army[:winnings][resourceType.to_sym]
    end

    mongo[:users].update_one({:_id => army[:userId]}, {'$inc' => inc})

    updateNetworthFor(mongo, army[:discordId])
end


def processAttack(attackingArmy, defendingArmy)
    attackingArmy[:power] = {}
    defendingArmy[:power] = {}

    attackingArmy[:bonus] = {}
    defendingArmy[:bonus] = {}

    attackingArmy[:loses] = {}
    defendingArmy[:loses] = {}

    attackingArmy[:percentage] = {}
    defendingArmy[:percentage] = {}

    attackingArmy[:finalPowerPerSoldier] = {}
    defendingArmy[:finalPowerPerSoldier] = {}

    # zero out
    $settings[:soldierTypes].each do |soldierType|
        attackingArmy[:power][soldierType.to_sym] = 0.0
        defendingArmy[:power][soldierType.to_sym] = 0.0

        attackingArmy[:bonus][soldierType.to_sym] = 0.0
        defendingArmy[:bonus][soldierType.to_sym] = 0.0

        attackingArmy[:loses][soldierType.to_sym] = 0
        defendingArmy[:loses][soldierType.to_sym] = 0

        attackingArmy[:percentage][soldierType.to_sym] = 0.0
        defendingArmy[:percentage][soldierType.to_sym] = 0.0

        attackingArmy[:finalPowerPerSoldier][soldierType.to_sym] = 0.0
        defendingArmy[:finalPowerPerSoldier][soldierType.to_sym] = 0.0
    end

    # get number of soldiers
    attackingArmy[:numSoldiers] = 0
    defendingArmy[:numSoldiers] = 0
    $settings[:soldierTypes].each do |soldierType|
        attackingArmy[:numSoldiers] += attackingArmy[soldierType.pluralize.to_sym].to_i
        defendingArmy[:numSoldiers] += defendingArmy[soldierType.pluralize.to_sym].to_i
    end

    # power
    attackingArmy[:totalPower] = 0.0
    defendingArmy[:totalPower] = 0.0
    $settings[:soldierTypes].each do |soldierType|
        attackingArmy[:power][soldierType.to_sym] = $settings[:soldiers][soldierType.to_sym][:attack] * attackingArmy[soldierType.pluralize.to_sym].to_f
        defendingArmy[:power][soldierType.to_sym] = $settings[:soldiers][soldierType.to_sym][:defense] * defendingArmy[soldierType.pluralize.to_sym].to_f
        attackingArmy[:totalPower] += attackingArmy[:power][soldierType.to_sym]
        defendingArmy[:totalPower] += defendingArmy[:power][soldierType.to_sym]
    end

    # percentage
    $settings[:soldierTypes].each do |soldierType|
        if attackingArmy[:numSoldiers] == 0
            attackingArmy[:percentage][soldierType.to_sym] = 0.0
        else
            attackingArmy[:percentage][soldierType.to_sym] = attackingArmy[soldierType.pluralize.to_sym].to_f / attackingArmy[:numSoldiers].to_f
        end
        
        if defendingArmy[:numSoldiers] == 0
            defendingArmy[:percentage][soldierType.to_sym] = 0.0
        else
            defendingArmy[:percentage][soldierType.to_sym] = defendingArmy[soldierType.pluralize.to_sym].to_f / defendingArmy[:numSoldiers].to_f
        end
    end

    # bonus
    attackingArmy[:totalBonus] = 0.0
    defendingArmy[:totalBonus] = 0.0
    $settings[:soldierTypes].each do |soldierType|
        $settings[:soldiers][soldierType.to_sym][:bonusAgainst].each do |bonusAgainst|
            attackBonus = attackingArmy[soldierType.pluralize.to_sym].to_f * defendingArmy[:percentage][bonusAgainst.to_sym] * $settings[:battleBonusMultiplier]
            defendBonus = defendingArmy[soldierType.pluralize.to_sym].to_f * attackingArmy[:percentage][bonusAgainst.to_sym] * $settings[:battleBonusMultiplier]

            attackingArmy[:bonus][soldierType.to_sym] += attackBonus
            defendingArmy[:bonus][soldierType.to_sym] += defendBonus

            attackingArmy[:totalBonus] += attackBonus
            defendingArmy[:totalBonus] += defendBonus
        end
    end

    # final power
    attackingArmy[:finalPower] = attackingArmy[:totalPower] + attackingArmy[:totalBonus]
    defendingArmy[:finalPower] = defendingArmy[:totalPower] + defendingArmy[:totalBonus]

    # final power of each soldier type
    $settings[:soldierTypes].each do |soldierType|
        if attackingArmy[soldierType.pluralize.to_sym].to_i == 0
            attackingArmy[:finalPowerPerSoldier][soldierType.to_sym] = 0.0
        else
            attackingArmy[:finalPowerPerSoldier][soldierType.to_sym] = (attackingArmy[:power][soldierType.to_sym] + attackingArmy[:bonus][soldierType.to_sym]) / attackingArmy[soldierType.pluralize.to_sym].to_f
        end

        if defendingArmy[soldierType.pluralize.to_sym].to_i == 0
            defendingArmy[:finalPowerPerSoldier][soldierType.to_sym] = 0.0
        else
            defendingArmy[:finalPowerPerSoldier][soldierType.to_sym] = (defendingArmy[:power][soldierType.to_sym] + defendingArmy[:bonus][soldierType.to_sym]) / defendingArmy[soldierType.pluralize.to_sym].to_f
        end
    end

    # who wins
    dif = attackingArmy[:finalPower] - defendingArmy[:finalPower]
    attackingArmy[:isWinner] = dif > 0
    defendingArmy[:isWinner] = dif <= 0

    # find power to lose
    if dif > 0
        attackingArmy[:powerToLose] = $settings[:battlePowerLostPerBattle] + ((attackingArmy[:finalPower] + defendingArmy[:finalPower]) / 500.0)
        attackingArmy[:powerToLose] = [attackingArmy[:powerToLose], defendingArmy[:finalPower]].min * $settings[:battlePowerLostWinnerRatio]
        defendingArmy[:powerToLose] = $settings[:battlePowerLostPerBattle] + ((attackingArmy[:finalPower] + defendingArmy[:finalPower]) / 500.0)
    else
        defendingArmy[:powerToLose] = $settings[:battlePowerLostPerBattle] + ((defendingArmy[:finalPower] + attackingArmy[:finalPower]) / 500.0)
        defendingArmy[:powerToLose] = [defendingArmy[:powerToLose], attackingArmy[:finalPower]].min * $settings[:battlePowerLostWinnerRatio]
        attackingArmy[:powerToLose] = $settings[:battlePowerLostPerBattle] + ((defendingArmy[:finalPower] + attackingArmy[:finalPower]) / 500.0)
    end

    findLoses(attackingArmy)
    findLoses(defendingArmy)
end


def findLoses(army)
    army[:numLoses] = 0

    if army[:numSoldiers] == 0
        return
    end

    # find which soldier is worth the least
    smallestSoldierPower = 999999
    $settings[:soldierTypes].each do |soldierType|
        if army[:finalPowerPerSoldier][soldierType.to_sym] > 0 && army[:finalPowerPerSoldier][soldierType.to_sym] < smallestSoldierPower
            smallestSoldierPower = army[:finalPowerPerSoldier][soldierType.to_sym]
        end
    end

    # take away until powerToLose is less than smallestSoldierPower
    fails = 0
    maxFails = $settings[:soldierTypes].length
    powerLeft = army[:powerToLose]
    numSoldiers = army[:numSoldiers]

    while powerLeft > 0 && numSoldiers > 0 && fails < maxFails do
        $settings[:soldierTypes].each do |soldierType|

            # if there is a unit of this type in the army
            if army[soldierType.pluralize.to_sym].to_i - army[:loses][soldierType.to_sym].to_i > 0

                #if there is enough power left to take this unit away
                if army[:finalPowerPerSoldier][soldierType.to_sym] <= powerLeft
                    army[:loses][soldierType.to_sym] += 1
                    numSoldiers -= 1
                    powerLeft -= army[:finalPowerPerSoldier][soldierType.to_sym]
                    army[:numLoses] += 1
                else
                    fails += 1
                end
            end
        end
    end
end