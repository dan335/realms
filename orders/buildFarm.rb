def order_buildFarm(order, mongo)
    # make sure user doesn't already have max farms
    if mongo[:farms].find(:discordId => order[:discordId]).count >= $settings[:maxFarms]
        return
    end

    # create farm
    mongo[:farms].insert_one({
        :discordId => order[:discordId],
        :wood => rand($settings[:farmMaxResourcesPerInterval]),
        :ore => rand($settings[:farmMaxResourcesPerInterval]),
        :wool => rand($settings[:farmMaxResourcesPerInterval]),
        :clay => rand($settings[:farmMaxResourcesPerInterval]),
        :createdAt => Time.now
    })
end