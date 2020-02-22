require './commonFunctions.rb'


def command_buy(bot, event, mongo)
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
        output_buy_error_message(event)
        return
    end

    # make sure resource type is valid
    type = arr[2].singularize
    if !$settings[:resourceTypes].include?(type)
        output_buy_error_message(event)
        return
    end

    # get user and market
    user = mongo[:users].find(:discordId => event.message.author.id).first

    market = mongo[:market].find(:type => type).first
    if !market
        output_buy_error_message(event)
        return
    end

    # make sure number is a number
    num = arr[1].to_f
    if arr[1].to_f <= 0.0
        if arr[1] == "max"
            num = maxBuy(user[:gold], market[:value])
        else
            output_buy_error_message(event)
            return
        end
    end

    # get gold amount from buy
    gold = totalOfBuy(market[:value], num)

    # does user have enough gold?
    # compare with delta for floating point errors
    if (user[:gold] - gold).abs > 0.000001
        event.respond "You do not have "+number_with_commas(gold)+" gold to buy "+number_with_commas(num)+" "+type+" "+event.message.author.mention+"."
        return
    end

    # update user
    set = {
        :gold => [user[:gold] - gold, 0.0].max,
        type.to_sym => [user[type.to_sym] + num, 0.0].max
    }
    mongo[:users].update_one({:_id => user[:_id]}, {"$set" => set})

    # update market
    updateMarketPrice(mongo, market, type, num, true)

    # respond
    event.respond event.message.author.mention+" bought "+number_with_commas(num).to_s+" "+type+" for "+number_with_commas(gold.round(2))+" gold."
end


def output_buy_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%buy 3 wood**."
end