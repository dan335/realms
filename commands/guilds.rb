def command_guilds(bot, event, mongo)
    str = "-] **REALMS GUILDS** [-\n\n"
    
    count = 1
    bot.servers.each do |num, server|
        str += count.to_s+". "+server.name+" - "+server.member_count.to_s+" members\n"
        count += 1
    end

    event.respond str
end
