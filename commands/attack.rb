require './commonFunctions.rb'


def command_attack(event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    if arr.length == 1
        # show help
        return
    end

    otherUser = nil

    # search by #
    if arr[1].to_i != 0
        otherUser = mongo[:users].find().sort(:networth => -1).skip(arr[1].to_i - 1).limit(1).first
    end

    # search by mention
    if otherUser == nil
        discordId = arr[1].gsub('<','').gsub('>','').gsub('@','').gsub('!','').to_i
        otherUser = mongo[:users].find(:discordId => discordId).first
    end

    # search by username
    if otherUser == nil
        otherUser = mongo[:users].find(:username => arr[1]).first
    end

    # search by display_name
    if otherUser == nil
        otherUser = mongo[:users].find(:display_name => arr[1]).first
    end

    if otherUser == nil
        event.respond "Could not find user "+arr[1]+" "+event.message.author.mention+"."
        return
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # maker sure you're not attack yourself
    # if user[:_id] == otherUser[:_id]
    #     event.respond "Attacking yourself? "+event.message.author.mention
    #     return
    # end

    # get soldiers
    army = {}
    $settings[:soldierTypes].each do |soldierType|
      army[soldierType.pluralize.to_sym] = 0
    end

    i = 2
    while i < arr.length do

        # check for correct number of parameters
        if arr.length < i + 2
            output_attack_syntax_message(event)
            return
        end

        # make sure number is a number
        if arr[i].to_i == 0
            output_attack_syntax_message(event)
            return
        end

        # make sure soldier type is valid
        if !$settings[:soldierTypes].include?(arr[i+1].singularize)
            output_attack_syntax_message(event)
            return
        end

        # make sure user has enough soldiers
        if user[arr[i+1].pluralize.to_sym] < arr[i].to_i
            event.respond "You do not have enough "+arr[i+1].pluralize+" "+event.message.author.mention
            return
        end

        army[arr[i+1].pluralize.to_sym] = arr[i].to_i

        i += 2
    end

    # get army travel time
    slowest = 99999
    $settings[:soldierTypes].each do |soldierType|
      if army[soldierType.pluralize.to_sym].to_i > 0
        s = $settings[:soldiers][soldierType.to_sym][:speed]
        if s < slowest
            slowest = s
        end
      end
    end
    durationSeconds = $settings[:armyTravelDistance] / slowest.to_f * 60.0

    # create army
    army[:discordId] = user[:discordId]
    army[:userId] = user[:_id]
    army[:createdAt] = Time.now
    army[:arriveAt] = Time.now + durationSeconds
    army[:otherDiscordId] = otherUser[:discordId]
    army[:otherUserId] = otherUser[:_id]
    army[:isAttacking] = true

    mongo[:armies].insert_one(army)

    # remove soldiers from user
    inc = {}
    $settings[:soldierTypes].each do |soldierType|
      inc[soldierType.pluralize.to_sym] = army[soldierType.pluralize.to_sym] * -1
    end

    mongo[:users].update_one({_id: user[:_id]}, {"$inc" => inc})

    updateNetworthFor(mongo, event.message.author.id)

    # spit out message
    event.respond "Your army is on it's way "+event.message.author.mention+"."
end


def output_attack_syntax_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%attack Danimal 3 footmen 2 archers**."
end
