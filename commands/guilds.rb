def command_guilds(bot, event, mongo)
    str = "-] **REALMS GUILDS** [-\n"

    # find page number
    page = 0

    msg = event.message.content
    msg.slice!(0)
    arr = msg.split

    if arr.length > 1
        t = arr[1].to_i
        if t == 0
            event.respond "Page "+arr[1]+" is not a valid page number "+event.message.author.mention+"."
            return
        end

        page = t - 1
    end

    # find number of pages
    str += "page "+(page+1).to_s+" of "+(bot.servers.length().to_f / $settings[:perPage].to_f).ceil.to_s+"\n"
    str += "\n"

    # print guilds
    count = 0
    bot.servers.each do |num, server|
        if count >= page * $settings[:perPage]
            if count < page * $settings[:perPage] + $settings[:perPage]
                str += (count+1).to_s+". "+server.name+" - "+server.member_count.to_s+" members\n"
            end
        end
        count += 1
    end

    event.respond str
end
