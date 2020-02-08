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

    if arr.length == 1
        # print help message

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
end