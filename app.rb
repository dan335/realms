require 'dotenv/load'
require 'mongo'
require 'discordrb'

require './commands/help.rb'
require './commands/joinGame.rb'
require './commands/leaveGame.rb'

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

bot.run