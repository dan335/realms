require './orders/buildFarm.rb'
require './orders/buildShrine.rb'


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
        inc = {}

        $settings[:resourceTypes].each do |resourceType|
            inc[resourceType.to_sym] = farm[resourceType.to_sym]
        end

        mongo[:users].update_one({:discordId => farm[:discordId]}, {"$inc" => inc})
    end
end



def feedArmies(mongo)
    mongo[:users].find().each do |user|

        inc = {}

        # zero out
        $settings[:soldierTypes].each do |soldierType|
            inc [soldierType.pluralize.to_sym] = 0
        end

        # zero out
        $settings[:resourceTypes].each do |resourceType|
            inc[resourceType.to_sym] = 0.0
        end


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

            if enough
                # remove from user
                $settings[:resourceTypes].each do |resourceType|
                    inc[resourceType.to_sym] += cost[resourceType.to_sym] * -1.0
                end
            else
                # destroy some soldiers

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
                killPercentage = [1.0 - percentage, 0.01].max

                inc[soldierType.pluralize.to_sym] = (user[soldierType.pluralize.to_sym].to_f * killPercentage).round.to_i * -1
            end
        end

        mongo[:users].update_one({:_id => user[:_id]}, {"$inc" => inc})
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
