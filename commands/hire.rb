require './commonFunctions.rb'


def command_hire(bot, event, mongo)

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

        markets = mongo[:market].find()

        str = "-] HIRE SOLDIERS [-\n\n"

        str += "example: **%hire 2 footman**\n"
        str += "Each soldier can carry "+$settings[:winningsSoldierCanCarry].to_s+" gold worth of resources.\n\n"

        $settings[:soldierTypes].each do |type|
            # get worth of soldier in gold
            gold = 0
            $settings[:soldiers][type.to_sym][:cost].each do |cost|
                gold += resourceToGold(markets, cost[:type], cost[:num])
            end

            str += "__**"+$settings[:soldiers][type.to_sym][:name]+"**__\n"
            str += "    cost: "

            counter = 0
            $settings[:soldiers][type.to_sym][:cost].each do |cost|
                str += cost[:num].to_s+" "+cost[:type]
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

            str += "    consumes every 10 minutes: "

            counter = 0
            $settings[:soldiers][type.to_sym][:consumes].each do |consume|
                str += consume[:num].to_s+" "+consume[:type]
                if counter < $settings[:soldiers][type.to_sym][:consumes].length - 1
                    str += ","
                end
                str += "  "
                counter += 1
            end

            str += "\n"

            str += "    worth "+number_with_commas(gold.round(1))+" gold\n"
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
    if arr[1].to_i <= 0
        output_error_message(event)
        return
    end

    # make sure soldier type is valid
    if !$settings[:soldierTypes].include?(arr[2].singularize.downcase)
        output_error_message(event)
        return
    end

    # get cost
    cost = {}
    $settings[:resourceTypes].each do |resourceType|
        cost[resourceType.to_sym] = 0.0
    end

    $settings[:soldiers][arr[2].singularize.downcase.to_sym][:cost].each do |c|
        cost[c[:type].to_sym] = arr[1].to_f * c[:num]
    end

    # get user
    user = mongo[:users].find(:discordId => event.message.author.id).first

    # does player have enough
    $settings[:resourceTypes].each do |resourceType|
        if user[resourceType.to_sym] < cost[resourceType.to_sym]
            event.respond "You need "+cost[resourceType.to_sym].round(2).to_s+" "+resourceType+" to buy "+number_with_commas(arr[1].to_i)+" "+arr[2].pluralize+" "+event.message.author.mention+"."
            return
        end
    end

    # does user have enough population
    if arr[1].to_i > user[:population]
        event.respond "You do not have enough population to hire "+number_with_commas(arr[1].to_i)+" "+arr[2].pluralize+" "+event.message.author.mention+"."
        return
    end

    # add soldiers to user and take away cost
    set = {}

    # take away population
    set[:population] = [user[:population] - arr[1].to_i, 0].max

    # resources
    $settings[:resourceTypes].each do |resourceType|
        if cost.key?(resourceType.to_sym) && cost[resourceType.to_sym] > 0.0
            set[resourceType.to_sym] = [user[resourceType.to_sym] - cost[resourceType.to_sym], 0.0].max
        end
    end

    # soldiers
    set[arr[2].pluralize.downcase.to_sym] = [user[arr[2].pluralize.downcase.to_sym] + arr[1].to_i, 0].max

    # udpate db
    mongo[:users].update_one({_id: user[:_id]}, {"$set" => set})

    if arr[1].to_i == 1
        event.respond event.message.author.mention+" hired "+number_with_commas(arr[1].to_i)+" "+arr[2].singularize+"."
    else
        event.respond event.message.author.mention+" hired "+number_with_commas(arr[1].to_i)+" "+arr[2].pluralize+"."
    end

    updateNetworthFor(mongo, event.message.author.id)
end


def output_error_message(event)
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like **%hire 3 footmen**."
end
