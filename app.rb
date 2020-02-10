require 'dotenv/load'
require 'mongo'
require 'discordrb'

require './settings.rb'
require './commonFunctions.rb'

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

require './orders/buildFarm.rb'

Mongo::Logger.logger.level = Logger::FATAL

bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])

bot.message(start_with: '%') do |event|

    # get function name from message
    cmd = event.message.content
    cmd.slice!(0)
    cmd = cmd.partition(" ").first
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

    # get orders that need to run
    # things like farms that need to be built
    mongo[:orders].find({:finishedAt => {'$lte' => Time.now}}).each do |order|

        # call function if it exists
        if respond_to?("order_"+order[:type].to_s, :include_private)
            send("order_"+order[:type].to_s, order, mongo)
        end

        # delete order
        mongo[:orders].delete_one(:_id => order[:_id])
    end

    # 10 minutes
    if loopNum % 10 == 0

        # give resources
        mongo[:farms].find().each do |farm|
            mongo[:users].update_one({:discordId => farm[:discordId]}, {
                    "$inc" => {
                        :wood => farm[:wood],
                        :ore => farm[:ore],
                        :wool => farm[:wool],
                        :clay => farm[:clay]
                    }
                })
        end

        updateNetworth(mongo)
    end

    ## attacks
    mongo[:armies].find({:finishedAt => {'$lte' => Time.now}}).each do |attack|

    end

    loopEnd = Time.now.to_i
    sleepFor = loopStart + 60 - loopEnd

    if sleepFor < 20
        sleepFor = 60
    end

    loopNum += 1

    sleep sleepFor
end