require './commonFunctions.rb'


def command_fire(bot, event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    # get type
    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    # check for wrong number of arguments
    if arr.length != 3
        output_error_message(event)
        return
    end

    # make sure number is a number
    if arr[1].to_i <= 0
        output_error_message(event)
        return
    end

    # make sure soldier type is valid
    if !$settings[:soldierTypes].include?(arr[2].singularize.downcase)
        output_error_message(event)
        return
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # does player have enough
    if user[arr[2].pluralize.downcase.to_sym] < arr[1].to_i
        event.respond "You don't have "+number_with_commas(arr[1].to_i)+" "+arr[2].pluralize+" "+event.message.author.mention+"."
        return
    end

    # add soldiers to user and take away cost
    set = {}

    # soldiers
    set[arr[2].pluralize.downcase.to_sym] = [user[arr[2].pluralize.downcase.to_sym] - arr[1].to_i, 0].max

    # udpate db
    mongo[:users].update_one({_id: user[:_id]}, {"$set" => set})

    if arr[1].to_i == 1
        event.respond event.message.author.mention+" fired "+number_with_commas(arr[1].to_i)+" "+arr[2].singularize+"."
    else
        event.respond event.message.author.mention+" fired "+number_with_commas(arr[1].to_i)+" "+arr[2].pluralize+"."
    end

    updateNetworthFor(mongo, event.message.author.id)
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%fire 3 footmen**."
end
