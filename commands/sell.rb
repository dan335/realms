require './commonFunctions.rb'


def command_sell(event, mongo)

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

    # does user have enough
    if user[arr[2].singularize.to_sym] < arr[1].to_i
        event.respond "You do not have "+number_with_commas(arr[1]).to_s+" "+arr[2]+" "+event.message.author.mention+"."
        return
    end

    # get gold amount from sell
    market = mongo[:market].find(:type => arr[2].singularize).first
    if !market
        output_error_message(event)
        return
    end
    gold = totalOfSell(market[:value], arr[1].to_i)

    # update user
    mongo[:users].update_one({:_id => user[:_id]}, {"$inc" => {:gold => gold, arr[2].singularize.to_sym => arr[1].to_i * -1}})

    # update market
    updateMarketPrice(mongo, market, arr[2].singularize, arr[1].to_i, false)

    # respond
    event.respond event.message.author.mention+" sold "+number_with_commas(arr[1].to_i).to_s+" "+arr[2].singularize+" for "+number_with_commas(gold.round(2)).to_s+" gold."
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%sell 3 wood**."
end


def totalOfSell(marketValue, quantity)
    marketValue * (1.0 - ((1.0 - $settings[:marketIncrement]) ** quantity.to_f)) / $settings[:marketIncrement]
end