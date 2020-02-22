require './commonFunctions.rb'


def command_attack(bot, event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use **%joinGame** to create one."
        return
    end

    # limit number of armies
    numArmies = mongo[:armies].find(:discordId => event.message.author.id).count
    if numArmies >= $settings[:maxArmiesPerPlayer]
        event.respond "You cannot create any more armies until one returns "+event.message.author.mention+".  "+$settings[:maxArmiesPerPlayer].to_s+" armies max."
        return
    end

    msg = event.message.content
    msg.slice!(0)
    words = msg.split

    if words.length == 1
        # show help
        return
    end

    otherUser = nil

    # search by #
    if words[1].to_i != 0
        otherUser = mongo[:users].find().sort(:networth => -1).skip(words[1].to_i - 1).limit(1).first
    end

    # search by mention
    if otherUser == nil
        discordId = words[1].gsub('<','').gsub('>','').gsub('@','').gsub('!','').to_i
        otherUser = mongo[:users].find(:discordId => discordId).first
    end

    # get name
    # may contain spaces
    wordNum = 1
    name = ""
    if otherUser == nil
        while wordNum < words.length && words[wordNum].to_i == 0
            if wordNum > 1
                name += " "
            end
            name += words[wordNum]
            wordNum += 1
        end
    else
        wordNum += 1
    end

    # search by username
    if otherUser == nil
        otherUser = mongo[:users].find(:username => name).first
    end

    # search by display_name
    if otherUser == nil
        otherUser = mongo[:users].find(:display_name => name).first
    end

    if otherUser == nil
        event.respond "Could not find user "+name+" "+event.message.author.mention+"."
        return
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # maker sure you're not attack yourself
    if ENV['MODE'] == 'production'
        if user[:_id] == otherUser[:_id]
            event.respond "Stop attacking yourself "+event.message.author.mention+"?"
            return
        end
    end

    # get soldiers
    army = {}
    $settings[:soldierTypes].each do |soldierType|
      army[soldierType.pluralize.to_sym] = 0
    end

    while wordNum < words.length do

        # check for correct number of parameters
        if words.length < wordNum + 2
            output_attack_syntax_message(event)
            return
        end

        # make sure number is a number
        if words[wordNum].to_i <= 0
            output_attack_syntax_message(event)
            return
        end

        # make sure soldier type is valid
        if !$settings[:soldierTypes].include?(words[wordNum+1].singularize)
            output_attack_syntax_message(event)
            return
        end

        # make sure user has enough soldiers
        if user[words[wordNum+1].pluralize.to_sym] < words[wordNum].to_i
            event.respond "You do not have enough "+words[wordNum+1].pluralize+" "+event.message.author.mention
            return
        end

        army[words[wordNum+1].pluralize.to_sym] = words[wordNum].to_i

        wordNum += 2
    end

    # get resources to feed army
    cost = {}
    $settings[:resourceTypes].each do |resourceType|
        cost[resourceType.to_sym] = 0.0
    end
    $settings[:soldierTypes].each do |soldierType|
        $settings[:soldiers][soldierType.to_sym][:consumes].each do |c|
            cost[c[:type].to_sym] += c[:num] * army[soldierType.pluralize.to_sym].to_f * armyTravelTime(army) / (60 * 10)
        end
    end

    # does user have enough resources to feed army
    enough = true
    $settings[:resourceTypes].each do |resourceType|
        if user[resourceType.to_sym] < cost[resourceType.to_sym]
            enough = false
        end
    end
    if !enough
        str = "You do not have enough resources to feed this army while it travels "+event.message.author.mention+".  Requires"
        $settings[:resourceTypes].each do |resourceType|
            if cost[resourceType.to_sym] > 0.0
                str += " "+cost[resourceType.to_sym].to_s+" "+resourceType
            end
        end
        event.respond str
        return
    end

    # create army
    army[:discordId] = user[:discordId]
    army[:userId] = user[:_id]
    army[:createdAt] = Time.now
    army[:arriveAt] = Time.now + armyTravelTime(army)
    army[:otherDiscordId] = otherUser[:discordId]
    army[:otherUserId] = otherUser[:_id]
    army[:isAttacking] = true

    mongo[:armies].insert_one(army)

    # remove soldiers and resources from user
    set = {}
    $settings[:soldierTypes].each do |soldierType|
      set[soldierType.pluralize.to_sym] = [user[soldierType.pluralize.to_sym] - army[soldierType.pluralize.to_sym], 0].max
    end
    $settings[:resourceTypes].each do |resourceType|
        if cost[resourceType.to_sym] > 0.0
            set[resourceType.to_sym] = [user[resourceType.to_sym] - cost[resourceType.to_sym], 0.0].max
        end
    end

    mongo[:users].update_one({_id: user[:_id]}, {"$set" => set})

    updateNetworthFor(mongo, event.message.author.id)

    # spit out message
    event.respond "Your army is on it's way "+event.message.author.mention+"."

    # send message to defender
    message = user[:display_name]+"'s army is headed towards your realm.  Use **%realm** to see how big it is."
    sendPM(bot, otherUser[:pmChannelId], message)
end


def output_attack_syntax_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%attack Danimal 3 footmen 2 archers**."
end
