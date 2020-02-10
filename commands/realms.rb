require './commonFunctions.rb'


def command_realms(event, mongo)
    str = "-] REALMS [-  "

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

    str += "*Attacking soldiers are not included.*\n\n"

    # get users
    counter = page * $settings[:perPage] + 1
    mongo[:users].find().sort(:networth => -1).skip(page * $settings[:perPage]).limit($settings[:perPage]).each do |user|
        str += counter.to_s+". **"+user[:username]+"** - networth: "+number_with_commas(user[:networth].round(2)).to_s+"  "

        $settings[:soldierTypes].each do |soldierType|
            str += soldierType.pluralize+": "+number_with_commas(user[soldierType.pluralize.to_sym]).to_s+"  "
        end

        str += "\n"

        counter += 1
    end

    event.respond str
end