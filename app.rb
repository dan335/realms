require 'dotenv/load'
require 'mongo'
require 'discordrb'

require './settings.rb'
require './commonFunctions.rb'
require 'active_support/core_ext/string'

require './commands/help.rb'
require './commands/commands.rb'
require './commands/joinGame.rb'
require './commands/leaveGame.rb'
require './commands/about.rb'
require './commands/build.rb'
require './commands/destroy.rb'
require './commands/realm.rb'
require './commands/realms.rb'
require './commands/hire.rb'
require './commands/attack.rb'
require './commands/cancelAttack.rb'
require './commands/market.rb'
require './commands/buy.rb'
require './commands/sell.rb'

require './orders/buildFarm.rb'

require './attacks.rb'

Mongo::Logger.logger.level = Logger::FATAL

bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])

validateMarket(mongo)

# handle incoming messages
bot.message(start_with: '%') do |event|

    # get function name from message
    cmd = event.message.content
    cmd.slice!(0)
    cmd = cmd.partition(" ").first.downcase
    cmd = 'command_'+cmd

    # call function if it exists
    if respond_to?(cmd, :include_private)
        send(cmd, event, mongo)
    end

end

bot.run true

loopNum = 1
updateNetworth(mongo)
while true do
    loopStart = Time.now.to_i

    ordersInterval(bot, mongo)

    # 10 minutes
    if loopNum % 10 == 0
        giveResources(mongo)
        feedArmies(mongo)
        updateNetworth(mongo)
    end

    attackInterval(bot, mongo)

    loopEnd = Time.now.to_i
    sleepFor = loopStart + 60 - loopEnd

    if sleepFor < 20
        sleepFor = 60
    end

    loopNum += 1

    sleep sleepFor
end