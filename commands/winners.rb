require './commonFunctions.rb'


def command_winners(bot, event, mongo)
    str = "-] **REALMS PAST WINNERS** [-  "

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
    numUsers = mongo[:winners].find().count

    str += "page "+(page+1).to_s+" of "+(numUsers.to_f / $settings[:perPage].to_f).ceil.to_s+"\n"

    str += "\n"

    # get users
    counter = page * $settings[:perPage] + 1
    mongo[:winners].find().sort(:endedAt => -1).skip(page * $settings[:perPage]).limit($settings[:perPage]).each do |user|
        str += counter.to_s+". **"+user[:display_name]+"** -"

        str += " "+user[:endedAt].to_formatted_s(:long)+","

        hours = ((user[:endedAt] - user[:startedAt]) / 60 / 60).round(1)
        str += " "+hours.to_s+" hours,"

        str += " "+number_with_commas(user[:networth].round)+"  networth,"

        str += " "+number_with_commas(user[:population])+"  population,"

        str += "  "+number_with_commas(user[:numShrinesBuilt])+" shrines built"

        str += "\n"
    end

    event.respond str

end