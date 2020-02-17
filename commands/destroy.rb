require './commonFunctions.rb'
require 'active_support/core_ext/string'

def command_destroy(bot, event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    # get type
    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    #make sure there is a type
    if arr.length < 3
        event.respond "I don't understand that command "+event.message.author.mention+".  Try something like __%destroy farm 1__."
        return
    end

    type = arr[1]
    num = arr[2].to_i

    dbName = type.pluralize.to_sym

    count = 1
    deleted = false

    mongo[dbName].find(:discordId => event.message.author.id).sort(:createdAt => 1).each do |building|
        if count == num
            mongo[dbName].find(:_id => building[:_id]).delete_one
            deleted = true
        end
        count += 1
    end

    if deleted
        event.respond "Your "+type+" has been destroyed "+event.message.author.mention+"."
    else
        event.respond "Count not find "+type+" "+num.to_s+" "+event.message.author.mention+"."
    end

end
