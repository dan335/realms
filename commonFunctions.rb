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
    net = user[:gold].to_i

    # resources
    $settings[:resourceTypes].each do |res|
        gold = resourceToGold(markets, res, user[res.to_sym].to_i)

        if gold != nil
            net += gold
        end
    end

    # soldiers
    $settings[:soldierTypes].each do |st|
        $settings[:soldiers][st.to_sym][:cost].each do |c|
            gold = resourceToGold(markets, c[:type], c[:num])

            if gold != nil
                net += user[st.pluralize.to_sym].to_i * gold
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
        quantity *= -1
    end

    value = value * (($settings[:marketIncrement] + 1) ** quantity)

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
    marketValue * (1.0 + $settings[:marketTax]) / $settings[:marketIncrement] * ((($settings[:marketIncrement] + 1.0) ** quantity) - 1.0)
end