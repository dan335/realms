require './commonFunctions.rb'


def command_realm(event, mongo)

    # get data
    user = mongo[:users].find(:discordId => event.message.author.id).first
    
    if user == nil
        event.respond "I can't find a realm for you " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    farms = mongo[:farms].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    orders = mongo[:orders].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    armies = mongo[:armies].find(:discordId => event.message.author.id).sort(:createdAt => 1)

    str = "-] **"+user[:username]+"'s REALM** [-\n"

    # resources
    str += "Gold: "+number_with_commas(user[:gold].to_f.round(2)).to_s+"  "
    str += "Wood: "+number_with_commas(user[:wood]).to_s+"  "
    str += "Ore: "+number_with_commas(user[:ore]).to_s+"  "
    str += "Wool: "+number_with_commas(user[:wool]).to_s+"  "
    str += "Clay: "+number_with_commas(user[:clay]).to_s
    str += "\n"

    #soldiers
    $settings[:soldierTypes].each do |soldierType|
        str += $settings[:soldiers][soldierType.to_sym][:name].pluralize+": "
        str += number_with_commas(user[soldierType.pluralize.to_sym]).to_s+"  "
    end
    str += "\n\n"

    # farms
    if farms.count > 0
        str += "__FARMS__ - *Resources harvested every 10 minutes.*\n"

        count = 1
        farms.each do |farm|
            str += count.to_s+".  Wood: "+farm[:wood].to_s+"  Ore: "+farm[:ore].to_s+"  Wool: "+farm[:wool].to_s+"  Clay: "+farm[:clay].to_s+"\n"
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
            str += count.to_s+". **"+order[:type].remove("build")+"** - "+minLeft.to_s+" minutes left.\n"
            count += 1
        end
    end

    # armies
    if armies.count > 0
        str += "__ARMIES__\n"

        count = 1
        armies.each do |army|
            str += count.to_s+". "

            s = 0
            army[:soldiers].each do |soldier|
                str += number_with_commas(soldier[:num]).to_s+" "
                str += soldier[:type].pluralize
                if s < army[:soldiers].length - 1
                    str += ",  "
                else
                    str += " "
                end
                s += 1
            end

            if army[:isAttacking]
                otherUser = mongo[:users].find(:_id => army[:otherUserId]).first
                str += "attacking "+otherUser[:username]+".  "
            else
                str += "returning.  "
            end

            str += "Arrives in "+((army[:arriveAt] - Time.now) / 60.0).round(1).to_s+" minutes."
            str += "\n"

            count += 1
        end
    end

    event.respond str
end