require './commonFunctions.rb'


def order_buildFarm(bot, order, mongo)
    # make sure user doesn't already have max farms
    if mongo[:farms].find(:discordId => order[:discordId]).count >= $settings[:maxFarms]
        return
    end

    # create farm
    farm = {
        :createdAt => Time.now,
        :discordId => order[:discordId]
    }

    $settings[:resourceTypes].each do |resourceType|
        farm[resourceType.to_sym] = rand($settings[:farmMaxResourcesPerInterval]).to_f
    end

    mongo[:farms].insert_one(farm)

    # send pm
    user = mongo[:users].find(:discordId => order[:discordId]).first
    if user
        sendPM(bot, user[:pmChannelId], "Your farm has finished building.  View your realm with **%realm**.")
    end
end