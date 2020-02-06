require 'dotenv/load'
require 'mongo'
require 'discordrb'

require './settings.rb'
require './commonFunctions.rb'

require './commands/help.rb'
require './commands/joinGame.rb'
require './commands/leaveGame.rb'
require './commands/about.rb'
require './commands/buildFarm.rb'

require './promises/buildFarm.rb'

Mongo::Logger.logger.level = Logger::FATAL

bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])

bot.message(start_with: '%') do |event|

    # get function name from message
    cmd = event.message.content
    cmd.slice!(0).strip!
    cmd = 'command_'+cmd

    # call function if it exists
    if respond_to?(cmd, :include_private)
        send(cmd, event, mongo)
    end

end

bot.run true

while true do
    loopStart = Time.now.to_i

    # get promises that need to run
    # things like farms that need to be built
    mongo[:promises].find({:finishedAt => {'$lte' => Time.now}}).each do |promise|

        # call function if it exists
        if respond_to?(promise[:type], :include_private)
            send(promise, mongo)
        end

        # delete promise
        mongo[:promises].delete_one(:_id => promise[:_id])
    end

    loopEnd = Time.now.to_i
    sleepFor = loopStart + 60 - loopEnd

    if sleepFor < 0
        sleepFor = 5
    end

    sleep sleepFor
end