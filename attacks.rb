require './commonFunctions.rb'
require 'active_support/core_ext/string'


# called every minute from app.rb
def attackInterval(bot, mongo)
    mongo[:armies].find({:arriveAt => {'$lte' => Time.now}}).each do |army|
        if army[:isAttacking]
            doAttack(bot, mongo, army)
        else
            returnToRealm(bot, mongo, army)
        end
        mongo[:armies].delete_one(:_id => army[:_id])
    end
end


def doAttack(bot, mongo, army)

    user = mongo[:users].find(:_id => army[:userId]).first
    attackingArmy = user.merge army
    defendingArmy = mongo[:users].find(:_id => army[:otherUserId]).first

    if !defendingArmy
        # get attackingArmy travel time
        slowest = 99999.0
        $settings[:soldierTypes].each do |soldierType|
            if attackingArmy[soldierType.pluralize.to_sym].to_i > 0
                s = $settings[:soldiers][soldierType.to_sym][:speed]
                if s < slowest
                    slowest = s
                end
            end
        end
        durationSeconds = $settings[:armyTravelDistance] / slowest.to_f * 60.0

        sendArmyToRealm(mongo, attackingArmy, nil, durationSeconds)
        return
    end

    # attack
    getNumberOfSoldiers(attackingArmy)
    getNumberOfSoldiers(defendingArmy)

    getPower(attackingArmy, true)
    getPower(defendingArmy, false)

    getPercentage(attackingArmy)
    getPercentage(defendingArmy)

    getBonus(attackingArmy, defendingArmy)

    getFinalPower(attackingArmy)
    getFinalPower(defendingArmy)

    getWinner(attackingArmy, defendingArmy)

    getPowerToLose(attackingArmy, defendingArmy)

    getLoses(attackingArmy)
    getLoses(defendingArmy)

    # get winnings
    winnings = getWinnings(attackingArmy, defendingArmy, mongo[:market].find())
    set = {:gold => [defendingArmy[:gold] - winnings[:gold], 0.0].max}
    $settings[:resourceTypes].each do |resourceType|
        set[resourceType.to_sym] = [defendingArmy[resourceType.to_sym] - winnings[resourceType.to_sym], 0.0].max
    end
    
    # save defendingArmy
    $settings[:soldierTypes].each do |soldierType|
        set[soldierType.pluralize.to_sym] = [defendingArmy[soldierType.pluralize.to_sym].to_i - defendingArmy[:loses][soldierType.to_sym], 0].max
    end
    mongo[:users].update_one({_id: defendingArmy[:_id]}, {"$set": set})
    updateNetworthFor(mongo, defendingArmy[:discordId])

    sendAttackReport(bot, attackingArmy, defendingArmy, winnings)

    # check if army is dead
    if attackingArmy[:numLoses] == attackingArmy[:numSoldiers]
        return
    end

    # take away loses
    $settings[:soldierTypes].each do |soldierType|
      attackingArmy[soldierType.pluralize.to_sym] = attackingArmy[soldierType.pluralize.to_sym].to_i - attackingArmy[:loses][soldierType.singularize.to_sym].to_i
    end

    # get attackingArmy travel time
    slowest = 99999.0
    $settings[:soldierTypes].each do |soldierType|
      if attackingArmy[soldierType.pluralize.to_sym].to_i > 0
        s = $settings[:soldiers][soldierType.to_sym][:speed]
        if s < slowest
            slowest = s
        end
      end
    end
    durationSeconds = $settings[:armyTravelDistance] / slowest.to_f * 60.0

    sendArmyToRealm(mongo, attackingArmy, winnings, durationSeconds)
end



def getWinnings(attackingArmy, defendingArmy, markets)
    winnings = {:gold => 0.0} # for winner
    canCarryInGold = (attackingArmy[:numSoldiers] - attackingArmy[:numLoses]) * $settings[:winningsSoldierCanCarry]

    if attackingArmy[:isWinner] && attackingArmy[:numLoses] < attackingArmy[:numSoldiers]
        winnings[:gold] = [defendingArmy[:gold] * $settings[:battleWinnings], canCarryInGold].min
        canCarryInGold -= winnings[:gold]
    end

    $settings[:resourceTypes].each do |resourceType|
        if attackingArmy[:isWinner] && attackingArmy[:numLoses] < attackingArmy[:numSoldiers]
            resourceWorth = resourceToGold(markets, resourceType, 1.0)

            steal = defendingArmy[resourceType.to_sym].to_f * $settings[:battleWinnings]
            steal = [canCarryInGold / resourceWorth, steal].min
            canCarryInGold -= [steal * resourceWorth, 0.0].max

            winnings[resourceType.to_sym] = steal
        else
            winnings[resourceType.to_sym] = 0.0
        end
    end

    return winnings
end




# used when attack is over and in %cancelattack
def sendArmyToRealm(mongo, army, winnings, durationSeconds)
  returningArmy = {
    :discordId => army[:discordId],
    :userId => army[:userId],
    :createdAt => Time.now,
    :arriveAt => Time.now + durationSeconds,
    :isAttacking => false,    # false if army is returning from battle
    :winnings => winnings
  }

  $settings[:soldierTypes].each do |soldierType|
    returningArmy[soldierType.pluralize.to_sym] = army[soldierType.pluralize.to_sym]
  end

  # create returning army
  mongo[:armies].insert_one(returningArmy)
end



# army has arrived at realm.  insert into realm
def returnToRealm(bot, mongo, army)
    user = mongo[:users].find(:_id => army[:userId]).first

    str = "**Your army returned from battle.**\n"

    str += "__Soldiers:__ "
    $settings[:soldierTypes].each do |soldierType|
      if army[soldierType.pluralize.to_sym].to_i > 0
        str += number_with_commas(army[soldierType.pluralize.to_sym].to_i)+ " "+soldierType.pluralize+"  "
      end
    end
    str += "\n"

    if army[:winnings]  # winnings can be nil
      str += "__Stole:__ "
      str += army[:winnings][:gold].round.to_s+" gold  "
      $settings[:resourceTypes].each do |resourceType|
          if army[:winnings][resourceType.to_sym] > 0.0
              str += number_with_commas(army[:winnings][resourceType.to_sym].round(1))+" "+resourceType+"  "
          end
      end
      str += "\n"
    end

    sendPM(bot, user[:pmChannelId], str)

    # add army back to user
    set = {}
    $settings[:soldierTypes].each do |soldierType|
      set[soldierType.pluralize.to_sym] = [user[soldierType.pluralize.to_sym] + army[soldierType.pluralize.to_sym].to_i, 0].max
    end

    if army[:winnings]
      set[:gold] = [user[:gold] + army[:winnings][:gold].to_f, 0.0].max

      $settings[:resourceTypes].each do |resourceType|
        set[resourceType.to_sym] = [user[resourceType.to_sym] + army[:winnings][resourceType.to_sym].to_f, 0.0].max
      end
    end

    mongo[:users].update_one({:_id => army[:userId]}, {'$set' => set})

    updateNetworthFor(mongo, user[:discordId])
end


def getNumberOfSoldiers(army)
  army[:numSoldiers] = 0

  $settings[:soldierTypes].each do |soldierType|
      army[:numSoldiers] += army[soldierType.pluralize.to_sym].to_i
  end
end


def getPower(army, isAttacker)
  army[:totalPower] = 0.0
  army[:power] = {}

  $settings[:soldierTypes].each do |soldierType|
      army[:power][soldierType.to_sym] = 0.0
  end

  $settings[:soldierTypes].each do |soldierType|
    if isAttacker
      army[:power][soldierType.to_sym] = $settings[:soldiers][soldierType.to_sym][:attack] * army[soldierType.pluralize.to_sym].to_f
    else
      army[:power][soldierType.to_sym] = $settings[:soldiers][soldierType.to_sym][:defense] * army[soldierType.pluralize.to_sym].to_f
    end
    army[:totalPower] += army[:power][soldierType.to_sym]
  end
end


def getPercentage(army)
  army[:percentage] = {}

  # count soldiers
  numSoldiers = 0.0
  $settings[:soldierTypes].each do |soldierType|
    numSoldiers += army[soldierType.pluralize.to_sym].to_f
  end

  $settings[:soldierTypes].each do |soldierType|
      #prevent divide by 0
      if numSoldiers == 0.0
          army[:percentage][soldierType.to_sym] = 0.0
      else
          army[:percentage][soldierType.to_sym] = army[soldierType.pluralize.to_sym].to_f / numSoldiers
      end
  end
end


def getBonus(attackingArmy, defendingArmy)
  attackingArmy[:totalBonus] = 0.0
  defendingArmy[:totalBonus] = 0.0
  attackingArmy[:bonus] = {}
  defendingArmy[:bonus] = {}

  $settings[:soldierTypes].each do |soldierType|
      attackingArmy[:bonus][soldierType.to_sym] = 0.0
      defendingArmy[:bonus][soldierType.to_sym] = 0.0
  end

  $settings[:soldierTypes].each do |soldierType|
      $settings[:soldiers][soldierType.to_sym][:bonusAgainst].each do |bonusAgainst|
          if defendingArmy[bonusAgainst.pluralize.to_sym] == 0
            attackBonus = 0.0
          else
            attackBonus = attackingArmy[:power][soldierType.to_sym] * defendingArmy[:percentage][bonusAgainst.to_sym] * $settings[:battleBonusMultiplier]
          end

          if attackingArmy[bonusAgainst.pluralize.to_sym] == 0
            defendBonus = 0.0
          else
            defendBonus = defendingArmy[:power][soldierType.to_sym] * attackingArmy[:percentage][bonusAgainst.to_sym] * $settings[:battleBonusMultiplier]
          end

          attackingArmy[:bonus][soldierType.to_sym] += attackBonus
          defendingArmy[:bonus][soldierType.to_sym] += defendBonus

          attackingArmy[:totalBonus] += attackBonus
          defendingArmy[:totalBonus] += defendBonus
      end
  end
end


def getFinalPower(army)
  army[:finalPowerPerSoldier] = {}

  # final power
  army[:finalPower] = army[:totalPower] + army[:totalBonus]

  # final power of each soldier type
  $settings[:soldierTypes].each do |soldierType|
      if army[soldierType.pluralize.to_sym].to_i == 0
          army[:finalPowerPerSoldier][soldierType.to_sym] = 0.0
      else
          army[:finalPowerPerSoldier][soldierType.to_sym] = (army[:power][soldierType.to_sym] + army[:bonus][soldierType.to_sym]) / army[soldierType.pluralize.to_sym].to_f
      end
  end
end


def getWinner(attackingArmy, defendingArmy)
  dif = attackingArmy[:finalPower] - defendingArmy[:finalPower]
  attackingArmy[:isWinner] = dif > 0
  defendingArmy[:isWinner] = dif <= 0
end


def getPowerToLose(attackingArmy, defendingArmy)
  if attackingArmy[:isWinner]
      attackingArmy[:powerToLose] = defendingArmy[:totalPower] * 0.1
      defendingArmy[:powerToLose] = defendingArmy[:totalPower] * 0.1
  else
      attackingArmy[:powerToLose] = [attackingArmy[:totalPower] * 0.5, defendingArmy[:totalPower] * 0.25].max
      defendingArmy[:powerToLose] = [attackingArmy[:totalPower] * 0.01, defendingArmy[:totalPower] * 0.01].min
  end
end


def getLoses(army)
    army[:numLoses] = 0
    army[:loses] = {}

    $settings[:soldierTypes].each do |soldierType|
        army[:loses][soldierType.to_sym] = 0
    end

    if army[:numSoldiers] == 0
      return
    end

    # find which soldier is worth the least
    smallestSoldierPower = 999999.0
    $settings[:soldierTypes].each do |soldierType|
        if army[:finalPowerPerSoldier][soldierType.to_sym] > 0.0 && army[:finalPowerPerSoldier][soldierType.to_sym] < smallestSoldierPower
            smallestSoldierPower = army[:finalPowerPerSoldier][soldierType.to_sym]
        end
    end

    # take away until powerToLose is less than smallestSoldierPower
    fails = 0
    maxFails = $settings[:soldierTypes].length * 2
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



def sendAttackReport(bot, attackingArmy, defendingArmy, winnings)
    str = "-] **ATTACK REPORT** [-\n\n"

    str += "__ATTACKING ARMY__\n"
    str += createReport(attackingArmy, true, winnings)
    str += "\n"
    str += "__DEFENDING REALM__\n"
    str += createReport(defendingArmy, false, nil)

    sendPM(bot, attackingArmy[:pmChannelId], str)
    sendPM(bot, defendingArmy[:pmChannelId], str)
end


def createReport(army, isAttacker, winnings)
    # sent
    str = "**"+army[:display_name]+"**"
    if isAttacker
        str += " sent "
    else
        str += " defended with "
    end

    $settings[:soldierTypes].each do |soldierType|
        if army[soldierType.pluralize.to_sym].to_i > 0
            str += number_with_commas(army[soldierType.pluralize.to_sym].to_i)+ " "+soldierType.pluralize+" "
        end
    end
    str += "\n"

    str += "__Power:__ "
    $settings[:soldierTypes].each do |soldierType|
        if army[:power][soldierType.to_sym].to_i > 0
            str += soldierType.pluralize+": "+number_with_commas(army[:power][soldierType.to_sym].round(1).to_f)+"  "
        end
    end
    str += "\n"

    str += "__Bonus:__ "
    if army[:totalBonus] > 0
        $settings[:soldierTypes].each do |soldierType|
            if army[:bonus][soldierType.to_sym].to_i > 0
                str += soldierType.pluralize+": "+number_with_commas(army[:bonus][soldierType.to_sym].round(1).to_f).to_s+"  "
            end
        end
    else
        str += "none"
    end
    str += "\n"

    str += number_with_commas(army[:totalPower].round(1))+" power + "+number_with_commas(army[:totalBonus].round(1))+" bonus = "+number_with_commas(army[:finalPower].round(1))+" final power\n"
    if army[:isWinner]
        str += "**Won Battle**\n"
    else
        str += "**Lost Battle**\n"
    end

    if army[:numLoses] > 0
        if army[:numLoses] == army[:numSoldiers]
            str += "Lost all soldiers."
        else
            str += "Lost "
            $settings[:soldierTypes].each do |soldierType|
                if army[:loses][soldierType.to_sym].to_i > 0
                    str += number_with_commas(army[:loses][soldierType.to_sym].to_i)+ " "+soldierType.pluralize+" "
                end
            end
        end
    else
      str += "Lost no soldiers."
    end
    str += "\n"

    if isAttacker && army[:isWinner]
        str += "__Stole:__ "
        str += number_with_commas(winnings[:gold].round(1))+" gold  "
        $settings[:resourceTypes].each do |resourceType|
            if winnings[resourceType.to_sym] > 0
                str += number_with_commas(winnings[resourceType.to_sym].to_f.round(1))+" "+resourceType+"  "
            end
        end
        str += "\n"
    end

    return str
end
