require './commonFunctions.rb'
require 'active_support/core_ext/string'


def command_realm(bot, event, mongo)

    # get data
    user = mongo[:users].find(:discordId => event.message.author.id).first

    if user == nil
        event.respond "I can't find a realm for you " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    farms = mongo[:farms].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    orders = mongo[:orders].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    armies = mongo[:armies].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    attackers = mongo[:armies].find({:otherDiscordId => event.message.author.id, :isAttacking => true}).sort(:createdAt => 1)

    str = "-] **"+user[:display_name]+"'s REALM** [-\n"

    # resources
    str += "Gold: "+number_with_commas(user[:gold].to_f.round(2)).to_s+"  "
    $settings[:resourceTypes].each do |resourceType|
        str += resourceType.camelize+": "+number_with_commas(user[resourceType.to_sym].to_f.round(2)).to_s+"  "
    end
    str += "\n"

    #soldiers
    $settings[:soldierTypes].each do |soldierType|
        str += $settings[:soldiers][soldierType.to_sym][:name].pluralize+": "
        str += number_with_commas(user[soldierType.pluralize.to_sym]).to_s+"  "
    end
    str += "\n"

    # soldiers consuming
    # get amounts
    cost = []
    isConsuming = false
    $settings[:soldierTypes].each do |soldierType|
        $settings[:soldiers][soldierType.to_sym][:consumes].each do |consume|
            if user[soldierType.pluralize.to_sym] > 0
                isConsuming = true
                index = cost.find_index do |i|
                    i[:type] == consume[:type]
                end
                if index
                    cost[index][:num] += consume[:num] * user[soldierType.pluralize.to_sym].to_f
                else
                    cost << {:type => consume[:type], :num => consume[:num] * user[soldierType.pluralize.to_sym].to_f}
                end
            end
        end
    end
    # output
    if isConsuming
        str += "Soldiers consuming "
        counter = 1
        cost.each do |c|
            str += c[:num].round(2).to_s+" "+c[:type]
            if counter < cost.length
                str += ","
            end
            str += " "
            counter += 1
        end
        str += "every 10 minutes.\n"
    end

    str += "\n"

    # farms
    if farms.count > 0
        str += "__FARMS__ - *Resources harvested every 10 minutes.*\n"

        count = 1
        farms.each do |farm|
            str += count.to_s+".  "
            $settings[:resourceTypes].each do |resourceType|
                str += resourceType.camelize+": "+farm[resourceType.to_sym].round.to_s+"  "
            end
            str += "\n"
            count += 1
        end

        str += "\n"
    end

    # orders
    if orders.count > 0
        str += "__CURRENTLY BUILDING__\n"

        count = 1
        orders.each do |order|
            minLeft = (((order[:finishedAt] - Time.now) / 60.0 * 10.0).round) / 10.0
            str += count.to_s+". **"+order[:type].remove("build")+"** - "+[minLeft, 0.0].max.to_s+" minutes left.\n"
            count += 1
        end

        str += "\n"
    end

    if farms.count == 0 && orders.count == 0
        str += "Type **%build farm** to build your first farm.\n\n"
    end

    # armies
    if armies.count > 0
        str += "__ARMIES__\n"

        count = 1
        armies.each do |army|
            str += count.to_s+". "

            s = 0
            $settings[:soldierTypes].each do |soldierType|
              if army[soldierType.pluralize.to_sym] > 0
                str += number_with_commas(army[soldierType.pluralize.to_sym]).to_s+" "
                str += soldierType.pluralize
                str += ",  "
                s += 1
              end
            end

            if army[:isAttacking]
                otherUser = mongo[:users].find(:_id => army[:otherUserId]).first
                str += "attacking "+otherUser[:display_name]+".  "
            else
                str += "returning.  "
            end

            str += "Arrives in "+[((army[:arriveAt] - Time.now) / 60.0).round(1), 0.0].max.to_s+" minutes."
            str += "\n"

            count += 1
        end

        str += "\n"
    end

    # attacking armies
    if attackers.count > 0
        str += "__ATTACKING ARMIES__\n"

        count = 1
        attackers.each do |army|
            str += count.to_s+". "

            otherUser = mongo[:users].find(:_id => army[:userId]).first
            str += otherUser[:display_name]+" is attacking with "

            s = 0
            $settings[:soldierTypes].each do |soldierType|
              if army[soldierType.pluralize.to_sym] > 0
                str += number_with_commas(army[soldierType.pluralize.to_sym]).to_s+" "
                str += soldierType.pluralize
                str += ",  "
                s += 1
              end
            end

            str += "Arrives in "+[((army[:arriveAt] - Time.now) / 60.0).round(1), 0.0].max.to_s+" minutes."
            str += "\n"

            count += 1
        end
    end

    event.respond str
end
