require './commonFunctions.rb'


def command_buy(event, mongo)
    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    # check for wrong number of arguments
    if arr.length != 3
        output_error_message(event)
        return
    end

    # make sure number is a number
    if arr[1].to_i == 0
        output_error_message(event)
        return
    end

    # make sure resource type is valid
    if !$settings[:resourceTypes].include?(arr[2].singularize)
        output_error_message(event)
        return
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # get gold amount from buy
    market = mongo[:market].find(:type => arr[2].singularize).first
    if !market
        output_error_message(event)
        return
    end
    gold = totalOfBuy(market[:value], arr[1].to_i)

    # does user have enough gold?
    if user[:gold] < gold
        event.respond "You do not have "+number_with_commas(gold.round(4)).to_s+" gold to buy "+number_with_commas(arr[1]).to_s+" "+arr[2]+" "+event.message.author.mention+"."
        return
    end

    # update user
    mongo[:users].update_one({:_id => user[:_id]}, {"$inc" => {:gold => gold * -1.0, arr[2].singularize.to_sym => arr[1].to_i}})

    # update market
    updateMarketPrice(mongo, market, arr[2].singularize, arr[1].to_i, true)

    # respond
    event.respond event.message.author.mention+" bought "+number_with_commas(arr[1].to_i).to_s+" "+arr[2].singularize+" for "+number_with_commas(gold.round(2)).to_s+" gold."
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%buy 3 wood**."
end


def totalOfBuy(marketValue, quantity)
    marketValue * (1.0 + $settings[:marketTax]) / $settings[:marketIncrement] * ((($settings[:marketIncrement] + 1.0) ** quantity) - 1.0)
end