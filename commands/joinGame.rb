require './commonFunctions.rb'
require 'active_support/core_ext/string'


def command_joingame(bot, event, mongo)

    if !event.server
        event.respond "Enter **%joinGame** in a guild channel not a private message to join the game."
        return
    end

    users = mongo[:users]

    # check if user exists
    if users.find(:discordId => event.message.author.id).count > 0
        event.respond "I already have a realm for you " + event.message.author.mention + ".  Cannot create another one.  Type **%realm** to view your realm."
        return
    end

    # save user to db
    user = {
        :discordId => event.message.author.id,
        :username => event.message.author.username.tr('`*-_', ''),
        :display_name => event.message.author.display_name.tr('`*-_', ''),
        :isOwner => event.message.author.owner?,
        :avatar_url => event.message.author.avatar_url,
        :mention => event.message.author.mention,
        :distinct => event.message.author.distinct,
        :discriminator => event.message.author.discriminator,
        :pmChannelId => event.message.author.pm.id,
        :serverId => event.server.id,
        :serverName => event.server.name,
        :gold => 0.0,
        :createdAt => Time.now,
        :networth => 0.0,
        :population => $settings[:startingPopulation],
        :happiness => 0.5,
        :tax => 0.05,
        :taxCollected => nil,
        :lastLostBattle => nil,
        :lastWonBattle => nil,
        :reputation => 0.5,
        :numShrinesBuilt => 0
    }

    $settings[:resourceTypes].each do |resourceType|
        user[resourceType.to_sym] = 0.0
    end

    $settings[:soldierTypes].each do |soldierType|
        user[soldierType.pluralize.to_sym] = 0
    end

    user[:grain] = 5.0
    user[:pikemen] = 5

    users.insert_one(user)

    event.respond "I found a nice plot of land for you "+ event.message.author.mention+".  Type **%realm** to check it out.  Welcome to REALMS."
end
