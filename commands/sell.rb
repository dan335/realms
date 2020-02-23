require './commonFunctions.rb'


def command_sell(bot, event, mongo)

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
        output_sell_error_message(event)
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
        output_sell_error_message(event)
        return
    end

    # make sure number is a number
    num = arr[1].to_f
    if num <= 0.0
        if arr[1] == "max"
            num = user[type.to_sym]
        else
            output_buy_error_message(event)
            return
        end
    end

    # does user have enough
    # compare with delta for floating point errors
    if arr[1] == "max"
        if (user[type.to_sym] - num).abs > 0.000001
            event.respond "You do not have "+number_with_commas(num)+" "+arr[2]+" "+event.message.author.mention+"."
            return
        end
    else
        if user[type.to_sym] < num
            event.respond "You do not have "+number_with_commas(num)+" "+arr[2]+" "+event.message.author.mention+"."
            return
        end
    end
    

    # get gold amount from sell
    gold = totalOfSell(market[:value], num)

    # update user
    set = {
        :gold => [user[:gold] + gold, 0.0].max,
        type.to_sym => [user[type.to_sym] - num, 0.0].max
    }
    mongo[:users].update_one({:_id => user[:_id]}, {"$set" => set})

    # update market
    updateMarketPrice(mongo, market, type, num, false)

    # respond
    event.respond event.message.author.mention+" sold "+number_with_commas(num.round(2))+" "+type+" for "+number_with_commas(gold.round(2))+" gold."
end


def output_sell_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%sell 3 wood**."
end
