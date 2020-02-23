require './orders/buildFarm.rb'
require './orders/buildShrine.rb'


def armyTravelTime(army)
    slowest = 99999
    $settings[:soldierTypes].each do |soldierType|
      if army[soldierType.pluralize.to_sym].to_i > 0
        s = $settings[:soldiers][soldierType.to_sym][:speed]
        if s < slowest
            slowest = s
        end
      end
    end
    return $settings[:armyTravelDistance] / slowest.to_f * 60.0
end


# called when someone wins the game
def resetGame(mongo)

    # drop buildings
    $settings[:buildingTypes].each do |buildingType|
        mongo[buildingType.pluralize.to_sym].drop()
    end

    mongo[:market].drop()
    mongo[:armies].drop()
    mongo[:orders].drop()
    mongo[:users].drop()

    validateMarket(mongo)
end



def isUserPlaying(mongo, discordId)
    if mongo[:users].find(:discordId => discordId).count == 0
        return false
    else
        return true
    end
end


# update networth for all players
def updateNetworth(mongo)
    bulk = []

    markets = mongo[:market].find()

    mongo[:users].find().each do |user|
        bulk << {:update_one => {
            :filter => {:_id => user[:_id]},
            :update => {'$set' => {:networth => calculateNetworthForUser(markets, user)}}
        }}
    end

    mongo[:users].bulk_write bulk
end


def updateNetworthFor(mongo, discordId)
    user = mongo[:users].find(:discordId => discordId).first
    markets = mongo[:market].find()

    if user
        mongo[:users].update_one({:_id => user[:_id]}, {'$set' => {:networth => calculateNetworthForUser(markets, user)}})
    end
end


def calculateNetworthForUser(markets, user)
    net = user[:gold]

    # resources
    $settings[:resourceTypes].each do |resourceType|
        gold = resourceToGold(markets, resourceType, user[resourceType.to_sym].to_f)

        if gold != nil
            net += gold
        end
    end

    # soldiers
    $settings[:soldierTypes].each do |soldierType|
        $settings[:soldiers][soldierType.to_sym][:cost].each do |cost|
            gold = resourceToGold(markets, cost[:type], cost[:num])

            if gold != nil
                net += user[soldierType.pluralize.to_sym].to_i * gold
            end
        end
    end

    net
end


def resourceToGold(markets, resourceType, quantity)
    market = nil

    markets.each do |m|
       if m[:type] == resourceType
            market = m
       end
    end

    if !market
        return nil
    end

    totalOfSell(market[:value], quantity)
end


# resourceObject is market data for resource from mongo
def updateMarketPrice(mongo, resourceObject, type, quantity, isBuy)
    value = resourceObject[:value]

    if !isBuy
        quantity *= -1.0
    end

    value = value * (($settings[:marketIncrement] + 1.0) ** quantity)

    mongo[:market].update_one({:_id => resourceObject[:_id]}, {"$set" => {value:value}})
end


# returns a string with commas
def number_with_commas(number)
    if number == nil
        return 0
    end
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join('.')
end


def totalOfSell(marketValue, quantity)
    marketValue * (1.0 - ((1.0 - $settings[:marketIncrement]) ** quantity.to_f)) / $settings[:marketIncrement]
end


def totalOfBuy(marketValue, quantity)
    marketValue * (1.0 + $settings[:marketTax]) / $settings[:marketIncrement] * ((($settings[:marketIncrement] + 1.0) ** quantity.to_f) - 1.0)
end


def maxBuy(gold, price)
    base = Math.log($settings[:marketIncrement] + 1)
    log = Math.log(gold * $settings[:marketIncrement] / (price * (1 + $settings[:marketTax])) + 1)
    return log / base
end


def sendPM(bot, channelId, message)
  begin
    channel = bot.channel(channelId)
    channel.send_message(message)
  rescue Exception => error
    puts "Bot received an error 403 from Discord"
    puts error
  end
end


def giveResources(mongo)
    mongo[:farms].find().each do |farm|
        set = {}

        user = mongo[:users].find(:discordId => farm[:discordId]).first

        $settings[:resourceTypes].each do |resourceType|
            set[resourceType.to_sym] = [user[resourceType.to_sym] + farm[resourceType.to_sym], 0.0].max
        end

        mongo[:users].update_one({:discordId => farm[:discordId]}, {"$set" => set})
    end
end



def feedArmies(bot, mongo)
    mongo[:users].find().each do |user|

        set = {}

        $settings[:soldierTypes].each do |soldierType|
            cost = {}

            # zero out
            $settings[:resourceTypes].each do |resourceType|
                cost[resourceType.to_sym] = 0.0
            end

            # get cost
            $settings[:soldiers][soldierType.to_sym][:consumes].each do |consume|
                cost[consume[:type].to_sym] += consume[:num] * user[soldierType.pluralize.to_sym].to_f
            end

            # have enough?
            enough = true
            $settings[:resourceTypes].each do |resourceType|
                if cost[resourceType.to_sym] > user[resourceType.to_sym]
                    enough = false
                end
            end

            # remove from user
            $settings[:resourceTypes].each do |resourceType|
                set[resourceType.to_sym] = [user[resourceType.to_sym] - cost[resourceType.to_sym], 0.0].max
            end

            # destroy some soldiers
            if !enough
                # get lowest percentage
                percentage = 1.0
                $settings[:resourceTypes].each do |resourceType|
                    if cost[resourceType.to_sym] > 0.0
                        p = user[resourceType.to_sym] / cost[resourceType.to_sym]
                        if p < percentage
                            percentage = p
                        end
                    end
                end

                # clamp
                killPercentage = [[percentage, 0.95].min, 1.0].max

                set[soldierType.pluralize.to_sym] = (user[soldierType.pluralize.to_sym].to_f * killPercentage).round.to_i

                sendPM(bot, user[:pmChannelId], "Your soldiers are dying from starvation.")
            end
        end

        mongo[:users].update_one({:_id => user[:_id]}, {"$set" => set})
    end
end



# make sure market exists and create if it doesn't
# runs when bot starts
def validateMarket(mongo)
    market = mongo[:market].find()

    isMarketValid = true
    $settings[:resourceTypes].each do |resourceType|
        exists = false

        market.each do |m|
            if m[:type] == resourceType
                exists = true
            end
        end

        if !exists
            isMarketValid = false
        end
    end

    # create market if not valid
    if !isMarketValid
        mongo[:market].drop

        $settings[:resourceTypes].each do |resourceType|
            mongo[:market].insert_one({
                :type => resourceType,
                :value => 10.0
            })
        end
    end
end



# get orders that need to run
# things like farms that need to be built
# called from app.rb every minute
def ordersInterval(bot, mongo)

    mongo[:orders].find({:finishedAt => {'$lte' => Time.now}}).each do |order|

        # call function if it exists
        if respond_to?("order_"+order[:type].to_s, :include_private)
            send("order_"+order[:type].to_s, bot, order, mongo)
        end

        # delete order
        mongo[:orders].delete_one(:_id => order[:_id])
    end
end



def getNewPopulation(previousPopulation, happiness)
    range = 0.2    # higher number makes population grow quicker
    population = (previousPopulation.to_f * (happiness * range + (1.0 - range) + (range / 2))).round.to_i
    [population, 0].max
end



def collectTaxes(mongo)
    spendingPerPerson = 0.1 # higher increases tax collected from population

    mongo[:users].find().each do |user|
        
        
        # find how many resources are collected by farms
        # zero out
        res = {}
        $settings[:resourceTypes].each do |resourceType|
            res[resourceType.to_sym] = 0.0
        end

        # get numbers from farms
        sum = 0.0
        mongo[:farms].find({:discordId => user[:discordId]}).each do |farm|
            $settings[:resourceTypes].each do |resourceType|
                res[resourceType.to_sym] += farm[resourceType.to_sym]
                sum += farm[resourceType.to_sym]
            end
        end

        # get percentages
        percentages = {}
        $settings[:resourceTypes].each do |resourceType|
            if sum == 0.0
                percentages[resourceType.to_sym] = 0.0
            else
                percentages[resourceType.to_sym] = res[resourceType.to_sym] / sum
            end
        end

        set = {}
        taxCollected = {}

        $settings[:resourceTypes].each do |resourceType|
            collected = user[:population].to_f * spendingPerPerson * user[:tax] * percentages[resourceType.to_sym]
            taxCollected[resourceType.to_sym] = collected
            set[resourceType.to_sym] = [user[resourceType.to_sym] + collected, 0.0].max
        end

        set[:taxCollected] = taxCollected
        mongo[:users].update_one({:_id => user[:_id]}, {"$set" => set})
    end
end



def getNewHappiness(happiness, tax)
    # find target happiness
    targetHappiness = 1.0 - slopeInterpolate(tax, 0.0, 1.0, 0.0, 1.0, 0.9)    # 0.33 is about even tax with 0.9 slope

    # slowly adjust towards targetHappiness
    lerp(happiness, targetHappiness, 0.1)
end


# linear interpolate by amount
# amount is 0.0 - 1.0
def lerp(from, to, amount)
    from + (to - from) * amount
end


# maps a linear range to a curved range
# used for tax
# value - value to be interpolated
# s1 - source range min
# s2 - source range max
# t1 - target range min
# t2 - target range max
# slope - Weight of the curve (0.5 = linear, 0.1 = weighted near target start, 0.9 = weighted near target end)
def slopeInterpolate(value, s1, s2, t1, t2, slope)
    # Reverse the value, to make it correspond to the target range (this is a side-effect of the bezier calculation)
    value = s2 - value

    # Find out how far the value is on the curve
    percent = value / (s2 - s1)

    c2y = t1 + slope.abs * (t2 - t1)
    b3 = (1 - percent) * (1 - percent)

    return t1 * (percent * percent) + c2y * (2 * percent * (1 - percent)) + t2 * b3
end


def is_number? string
    true if Float(string) rescue false
end


def getGoldInterest(gold)
    [gold * (1.0 + $settings[:goldInterestRate]), 0.0].max
end