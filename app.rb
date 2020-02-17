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

# maker sure market exists
market = mongo[:market].find()

isMarketValid = true
$settings[:resourceTypes].each do |resourceType|
    exists = false

    market.each do |m|
        if m[:type] == resourceType
            exists = true
        end
    end

    if !exists
        isMarketValid = false
    end
end

# create market if not valid
if !isMarketValid
    mongo[:market].drop

    $settings[:resourceTypes].each do |resourceType|
        mongo[:market].insert_one({
            :type => resourceType,
            :value => 10.0
        })
    end
end

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

    # get orders that need to run
    # things like farms that need to be built
    mongo[:orders].find({:finishedAt => {'$lte' => Time.now}}).each do |order|

        # call function if it exists
        if respond_to?("order_"+order[:type].to_s, :include_private)
            send("order_"+order[:type].to_s, bot, order, mongo)
        end

        # delete order
        mongo[:orders].delete_one(:_id => order[:_id])
    end

    # 10 minutes
    if loopNum % 10 == 0
        giveResources(mongo)
        feedArmies(mongo)
        updateNetworth(mongo)
    end

    ## attacks
    mongo[:armies].find({:arriveAt => {'$lte' => Time.now}}).each do |army|
        if army[:isAttacking]
            doAttack(bot, mongo, army)
        else
            returnToRealm(bot, mongo, army)
        end
        mongo[:armies].delete_one(:_id => army[:_id])
    end

    loopEnd = Time.now.to_i
    sleepFor = loopStart + 60 - loopEnd

    if sleepFor < 20
        sleepFor = 60
    end

    loopNum += 1

    sleep sleepFor
end



def giveResources(mongo)
    mongo[:farms].find().each do |farm|
        inc = {}

        $settings[:resourceTypes].each do |resourceType|
            inc[resourceType.to_sym] = farm[resourceType.to_sym]
        end

        mongo[:users].update_one({:discordId => farm[:discordId]}, {"$inc" => inc})
    end
end



def feedArmies(mongo)
    mongo[:users].find().each do |user|

        inc = {}

        # zero out
        $settings[:soldierTypes].each do |soldierType|
            inc [soldierType.pluralize.to_sym] = 0
        end

        # zero out
        $settings[:resourceTypes].each do |resourceType|
            inc[resourceType.to_sym] = 0.0
        end


        $settings[:soldierTypes].each do |soldierType|
            cost = {}

            # zero out
            $settings[:resourceTypes].each do |resourceType|
                cost[resourceType.to_sym] = 0.0
            end

            # get cost
            $settings[:soldiers][soldierType.to_sym][:consumes].each do |consume|
                cost[consume[:type].to_sym] += consume[:num] * user[soldierType.pluralize.to_sym].to_f
            end

            # have enough?
            enough = true
            $settings[:resourceTypes].each do |resourceType|
                if cost[resourceType.to_sym] > user[resourceType.to_sym]
                    enough = false
                end
            end

            if enough
                # remove from user
                $settings[:resourceTypes].each do |resourceType|
                    inc[resourceType.to_sym] += cost[resourceType.to_sym] * -1.0
                end
            else
                # destroy some soldiers

                # get lowest percentage
                percentage = 1.0
                $settings[:resourceTypes].each do |resourceType|
                    p = user[resourceType.to_sym] / cost[resourceType.to_sym]
                    if p < percentage
                        percentage = p
                    end
                end

                # clamp
                killPercentage = [1.0 - percentage, 0.01].max

                inc[soldierType.pluralize.to_sym] = (user[soldierType.pluralize.to_sym].to_f * killPercentage).round.to_i * -1
            end
        end

        mongo[:users].update_one({:_id => user[:_id]}, {"$inc" => inc})
    end
end
