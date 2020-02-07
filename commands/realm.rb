def command_realm(event, mongo)

    # get data
    user = mongo[:users].find(:discordId => event.message.author.id).first
    
    if user == nil
        event.respond "I can't find a realm for you " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    farms = mongo[:farms].find(:discordId => event.message.author.id).sort(:createdAt => 1)
    orders = mongo[:orders].find(:discordId => event.message.author.id)

    str = "**"+user[:username]+"'s REALM**\n"

    # resources
    str += "wood: "+user[:wood].to_s+" "
    str += "ore: "+user[:ore].to_s+" "
    str += "wool: "+user[:wool].to_s+" "
    str += "clay: "+user[:clay].to_s
    str += "\n\n"

    # farms
    if farms.count > 0
        str += "__FARMS__\n"

        count = 1
        farms.each do |farm|
            str += count.to_s+". wood: "+farm[:wood].to_s+" ore: "+farm[:ore].to_s+" wool: "+farm[:wool].to_s+" clay: "+farm[:clay].to_s+"\n"
            count += 1
        end

        str += "\n"
    end

    #orders
    if orders.count > 0
        str += "__CURRENTLY BUILDING__\n"
        
        count = 1
        orders.each do |order|
            minLeft = (((order[:finishedAt] - Time.now) / 60.0 * 10.0).round) / 10.0
            str += count.to_s+". **"+order[:type].remove("build")+"** - "+minLeft.to_s+" minutes left.\n"
            count += 1
        end
    end

    event.respond str
end