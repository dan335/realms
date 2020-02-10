require './commonFunctions.rb'


def command_hire(event, mongo)

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
        
        str = "-] HIRE SOLDIERS [-\n\n"

        str += "example: **%hire 2 footman**\n\n"

        $settings[:soldierTypes].each do |type|
            str += "__**"+$settings[:soldiers][type.to_sym][:name]+"**__\n"
            str += "    cost: "

            counter = 0
            $settings[:soldiers][type.to_sym][:cost].each do |res|
                str += res[:num].to_s+" "+res[:type]
                if counter < $settings[:soldiers][type.to_sym][:cost].length - 1
                    str += ","
                end
                str += "  "
                counter += 1
            end

            str += "\n"
            str += "    bonus against:"
            if $settings[:soldiers][type.to_sym][:bonusAgainst].length == 0
                str += "  none"
            else
                counter = 0
                $settings[:soldiers][type.to_sym][:bonusAgainst].each do |t|
                    str += "  "
                    str += t.pluralize
                    if counter < $settings[:soldiers][type.to_sym][:bonusAgainst].length - 1
                        str += ","
                    end
                    counter += 1
                end
            end

            str += "\n"
            str += "    attack: "+$settings[:soldiers][type.to_sym][:attack].to_s
            str += "  defense: "+$settings[:soldiers][type.to_sym][:defense].to_s
            str += "  speed: "+$settings[:soldiers][type.to_sym][:speed].to_s

            str += "\n"
        end

        event.respond str
        return
    end

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

    # make soldier type is valid
    if !$settings[:soldierTypes].include?(arr[2].singularize)
        output_error_message(event)
        return
    end

    # get cost
    cost = {}
    $settings[:resourceTypes].each do |t|
        cost[t.to_sym] = 0
    end

    soldierInfo = $settings[:soldiers][arr[2].singularize.to_sym]

    soldierInfo[:cost].each do |t|
        cost[t[:type].to_sym] = arr[1].to_i * t[:num]
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # does player have enough
    $settings[:resourceTypes].each do |t|
        if user[t.to_sym] < cost[t.to_sym]
            event.respond "You do not have enough "+t+" to buy "+arr[1]+" "+arr[2].pluralize+" "+event.message.author.mention+"."
            return
        end
    end

    # add soldiers to user and take away cost
    inc = {}

    # resources
    $settings[:resourceTypes].each do |r|
        if cost.key?(r.to_sym) && cost[r.to_sym] > 0
            inc[r.to_sym] = cost[r.to_sym] * -1
        end
    end

    # soldiers
    inc[arr[2].pluralize.to_sym] = arr[1].to_i

    # udpate db
    mongo[:users].update_one({_id: user[:_id]}, {"$inc" => inc})

    if arr[1].to_i == 1
        event.respond event.message.author.mention+" hired "+arr[1].to_s+" "+arr[2].singularize+"."
    else
        event.respond event.message.author.mention+" hired "+arr[1].to_s+" "+arr[2].pluralize+"."
    end
    
    updateNetworthFor(mongo, mongo, event.message.author.id)
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%hire 3 footmen**."
end