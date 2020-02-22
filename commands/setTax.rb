require './commonFunctions.rb'
require 'active_support/core_ext/string'

def command_settax(bot, event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    # split up message
    msg = event.message.content
    msg.slice!(0)
    arr = msg.split
    arr[1] = arr[1].gsub('%','')

    # check for wrong number of arguments
    if arr.length != 2
        output_error_message(event)
        return
    end

    # make sure number is a number
    if !is_number? arr[1]
        output_error_message(event)
        return
    end

    tax = arr[1].to_f / 100.0

    # less than 0
    if tax < 0.0
        output_error_message(event)
        return
    end

    # more than 100
    if tax > 1.0
        output_error_message(event)
        return
    end

    # udpate db
    mongo[:users].update_one({:discordId => event.message.author.id}, {"$set" => {:tax => tax}})

    # print out message
    event.respond "Your tax rate has been set to "+(tax*100.0).to_s+"% "+event.message.author.mention+"."
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%setTax 15**."
end