require './commonFunctions.rb'


def order_buildShrine(bot, order, mongo)
    # make sure user doesn't already have max
    if mongo[:shrines].find(:discordId => order[:discordId]).count >= $settings[:buildings][:shrine][:max]

        return
    end

    user = mongo[:users].find(:discordId => order[:discordId]).first

    # create shrine
    shrine = {
        :createdAt => Time.now,
        :discordId => order[:discordId],
        :userId => user[:_id]
    }

    mongo[:shrines].insert_one(shrine)

    numShrines = mongo[:shrines].find(:userId => user[:_id]).count

    mongo[:users].update_one({:_id => user[:_id]}, {"$set" => {:numShrinesBuilt => user[:numShrinesBuilt] + 1}})

    if numShrines >= $settings[:buildings][:shrine][:max]
        # game over
        mongo[:users].find().each do |u|
            sendPM(bot, u[:pmChannelId], user[:display_name]+" wins.  Congrats!  REALMS has been reset.  Type **%joinGame** to join the new game.")
        end
        user[:numShrinesBuilt] = user[:numShrinesBuilt] + 1
        resetGame(mongo, user)
    else
        sendPM(bot, user[:pmChannelId], "Your shrine has finished building.  View your realm with **%realm**.")
        updateNetworthFor(mongo, user[:discordId])
    end
end