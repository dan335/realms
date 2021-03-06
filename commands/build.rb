require './commonFunctions.rb'
require 'active_support/core_ext/string'

def command_build(bot, event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    # get type
    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    # print help message
    if arr.length == 1
        str = "-] BUILD [-\n\n"
        str += "example: **%build farm**\n\n"
        str += "__Farms__\n"
        str += "    "+$settings[:buildings][:farm][:description]+"\n\n"
        str += "__Shrines__\n"
        str += "    "+$settings[:buildings][:shrine][:description]+"  Cost: "

        $settings[:buildings][:shrine][:cost].each do |c|
            str += number_with_commas(c[:num])+" "+c[:type]+", "
        end
        
        str += "\n"
        event.respond str
        return
    end

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
    max = $settings[:buildings][type.singularize.to_sym][:max]
    timeToBuild = $settings[:buildings][type.singularize.to_sym][:buildSeconds]
    orderType = "build"+type.camelize

    # check how many user has already built
    numBeingBuilt = mongo[:orders].find({
        :discordId => event.message.author.id,
        :type => orderType
    }).count

    num = mongo[dbName].find({
        :discordId => event.message.author.id
    }).count

    if num + numBeingBuilt >= max
        event.respond "No more room for "+type.pluralize+" in your realm " + event.message.author.mention + ".  Destroy one to create another."
        return
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # check cost
    if $settings[:buildings][type.singularize.to_sym][:cost].length > 0
        enough = true
        $settings[:buildings][type.to_sym][:cost].each do |cost|
            if user[cost[:type].to_sym] < cost[:num]
                enough = false
            end
        end

        if !enough
            event.respond "You do not have enough resources to build a "+type+" "+event.message.author.mention+".  Use %build to view prices."
            return
        end

        # take away cost from user
        set = {}
        $settings[:buildings][type.to_sym][:cost].each do |cost|
            set[cost[:type].to_sym] = [user[cost[:type].to_sym] - cost[:num], 0.0].max
        end
        mongo[:users].update_one({_id: user[:_id]}, {"$set": set})
    end

    # create order to build farm in the future
    mongo[:orders].insert_one({
        :discordId => event.message.author.id,
        :type => orderType,
        :createdAt => Time.now,
        :finishedAt => Time.now + timeToBuild
    })

    # if shrine increment num shrines built
    if orderType == "buildShrine"
        mongo[:users].update_one({:discordId => event.message.author.id}, {"$set" => {:numShrinesBuilt => user[:numShrinesBuilt] + 1}})
    end

    event.respond "I'm building you a "+type+" " + event.message.author.mention + ".  Check its progress with **%realm**."

    updateNetworthFor(mongo, event.message.author.id)
end
