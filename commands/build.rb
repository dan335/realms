require './commonFunctions.rb'
require 'active_support/core_ext/string'

def command_build(event, mongo)

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
    if arr.length < 2
        event.respond "I don't understand that command "+event.message.author.mention+".  Try something like __%build farm__."
        return
    end

    # make sure type is a valid building
    if !$settings[:buildingTypes].include?(arr[1].singularize)
        event.respond "I don't understand that command "+event.message.author.mention+".  Try something like __%build farm__."
        return
    end

    type = arr[1]
    dbName = type.pluralize.to_sym
    max = ("max"+type.pluralize.camelize).to_sym
    timeToBuild = (type+"BuildSeconds").to_sym
    orderType = "build"+type.camelize

    # check how many user has already built
    numBeingBuilt = mongo[:orders].find({
        :discordId => event.message.author.id,
        :type => orderType
    }).count

    num = mongo[dbName].find({
        :discordId => event.message.author.id
    }).count

    if num + numBeingBuilt >= $settings[max]
        event.respond "No more room for "+type.pluralize+" in your realm " + event.message.author.mention + ".  Destroy one to create another."
        return
    end

    # create order to build farm in the future
    mongo[:orders].insert_one({
        :discordId => event.message.author.id,
        :type => orderType,
        :createdAt => Time.now,
        :finishedAt => Time.now + $settings[timeToBuild]
    })

    event.respond "I'm building you a new "+type+" " + event.message.author.mention + ".  Check its progress with __%realm__."
end