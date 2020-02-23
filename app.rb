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
require './commands/setTax.rb'

require './attacks.rb'

Mongo::Logger.logger.level = Logger::FATAL

bot = Discordrb::Bot.new token: ENV['DISCORD_TOKEN']
mongo = Mongo::Client.new([ ENV['MONGO_URL'] ], :database => ENV['MONGO_DB'])

# create mongodb indexes
mongo[:users].indexes.create_one({:discordId => 1}, unique: true )
mongo[:users].indexes.create_one({:networth => -1})
mongo[:armies].indexes.create_one({:arriveAt => 1})
mongo[:armies].indexes.create_one({:discordId => 1})
mongo[:armies].indexes.create_many([
  {:key => {:discordId => 1}},
  {:key => {:createdAt => 1}}
])
mongo[:armies].indexes.create_many([
  {:key => {:discordId => 1}},
  {:key => {:createdAt => 1}},
  {:key => {:isAttacking => 1}}
])
mongo[:orders].indexes.create_one({:discordId => 1})
mongo[:orders].indexes.create_many([
  {:key => {:discordId => 1}},
  {:key => {:type => 1}}
])
mongo[:orders].indexes.create_one({:finishedAt => 1})
mongo[:farms].indexes.create_one({:discordId => 1})
mongo[:farms].indexes.create_many([
  {:key => {:discordId => 1}},
  {:key => {:createdAt => 1}}
])
mongo[:shrines].indexes.create_one({:discordId => 1})
mongo[:shrines].indexes.create_many([
  {:key => {:discordId => 1}},
  {:key => {:createdAt => 1}}
])
mongo[:market].indexes.create_one({:type => 1})


# temp - remove next game
mongo[:users].update_many({:population => {"$exists" => false}}, {"$set" => {:population => 100}})
mongo[:users].update_many({:happiness => {"$exists" => false}}, {"$set" => {:happiness => 0.5}})
mongo[:users].update_many({:tax => {"$exists" => false}}, {"$set" => {:tax => 0.05}})
mongo[:users].update_many({:taxCollected => {"$exists" => false}}, {"$set" => {:taxCollected => nil}})


validateMarket(mongo)

# make sure soldiers are never 0
mongo[:users].find().each do |user|
  $settings[:soldierTypes].each do |soldierType|
    if user[soldierType.pluralize.to_sym] < 0
      mongo[:users].update_one({:_id => user[:_id]}, {"$set" => {soldierType.pluralize.to_sym => 0}})
    end
  end
end

puts "-] REALMS [-"

# handle incoming messages
bot.message(start_with: '%') do |event|

    # get function name from message
    cmd = event.message.content.downcase
    cmd.slice!(0)
    cmd = cmd.partition(" ").first
    cmd = 'command_'+cmd

    # call function if it exists
    if respond_to?(cmd, :include_private)
        send(cmd, bot, event, mongo)
    end

end

bot.run true
collectTaxes(mongo)
# game loop
loopNum = 1
updateNetworth(mongo)
while true do
    loopStart = Time.now.to_i
 
    ordersInterval(bot, mongo)

    # 10 minutes
    if loopNum % 10 == 0
        giveResources(mongo)
        feedArmies(bot, mongo)

        mongo[:users].find().each do |user|
          mongo[:users].update_one({:_id => user[:_id]}, {"$set" => {
            :population => getNewPopulation(user[:population], user[:happiness]),
            :happiness => getNewHappiness(user[:happiness], user[:tax]),
            :gold => getGoldInterest(user[:gold])
            }})
        end

        collectTaxes(mongo)
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
