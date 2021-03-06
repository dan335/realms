require './commonFunctions.rb'


def command_realms(bot, event, mongo)
    str = "-] **REALMS** [-  "

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
    numUsers = mongo[:users].find().count

    str += "page "+(page+1).to_s+" of "+(numUsers.to_f / $settings[:perPage].to_f).ceil.to_s+"\n"

    str += "Sept 2nd: Each shrine causes your population to grow faster.\n"

    str += "\n"

    # get users
    counter = page * $settings[:perPage] + 1
    mongo[:users].find().sort(:networth => -1).skip(page * $settings[:perPage]).limit($settings[:perPage]).each do |user|
        numShrines = mongo[:shrines].find(:userId => user[:_id]).count
        numShrinesBeingBuilt = mongo[:orders].find({:discordId => user[:discordId], :type => "buildShrine"}).count

        str += counter.to_s+". **"+user[:display_name]+"** - networth: **"+number_with_commas(user[:networth].round)+"**,  "

        hasShrine = false
        numShrines.times do
            str += ":shinto_shrine:"
            hasShrine = true
        end

        numShrinesBeingBuilt.times do
            str += ":tools:"
            hasShrine = true
        end

        if hasShrine
            str += "  "
        end

        num = 0
        $settings[:soldierTypes].each do |soldierType|
            str += $settings[:soldiers][soldierType.to_sym][:name].pluralize+": **"+number_with_commas(user[soldierType.pluralize.to_sym])+"**"
            if num < $settings[:soldierTypes].length - 1
                str += ",  "
            end
            num += 1
        end

        str += "\n"

        counter += 1
    end

    event.respond str
end
