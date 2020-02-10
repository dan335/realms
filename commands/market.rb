require './commonFunctions.rb'


def command_market(event, mongo)
    str = "-] REALMS MARKET [-\n\n"

    mongo[:market].find().each do |res|
        str += res[:type].camelize+": "+number_with_commas(res[:value].round(4)).to_s+"\n"
    end

    event.respond str
end