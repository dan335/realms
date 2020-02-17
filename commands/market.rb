require './commonFunctions.rb'


def command_market(bot, event, mongo)
    str = "-] **REALMS MARKET** [-\n"
    str += "*"+($settings[:marketTax] * 100.0).to_s+"% tax when buying*\n\n"

    mongo[:market].find().each do |res|
        str += res[:type].camelize+":  "+number_with_commas(res[:value].round(4)).to_s+" gold\n"
    end

    event.respond str
end
