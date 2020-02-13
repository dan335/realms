require './commonFunctions.rb'

def command_joinGame(event, mongo)

    if !event.server
        event.respond "Enter **%joinGame** in a guild channel not a private message to join the game."
        return
    end

    users = mongo[:users]

    # check if user exists
    if users.find(:discordId => event.message.author.id).count > 0
        event.respond "I already have a realm for you " + event.message.author.mention + ".  Cannot create another one."
        return
    end

    # save user to db
    users.insert_one({
        :discordId => event.message.author.id,
        :username => event.message.author.username,
        :display_name => event.message.author.display_name,
        :isOwner => event.message.author.owner?,
        :avatar_url => event.message.author.avatar_url,
        :mention => event.message.author.mention,
        :distinct => event.message.author.distinct,
        :discriminator => event.message.author.discriminator,
        :pmChannelId => event.message.author.pm.id,
        :serverId => event.server.id,
        :serverName => event.server.name,
        :wood => 0,
        :ore => 0,
        :wool => 0,
        :clay => 0,
        :gold => 0.0,
        :createdAt => Time.now,
        :footmen => 0,
        :archers => 0,
        :pikemen => 5,
        :knights => 0,
        :catapults => 0,
        :networth => 0.0
    })

    event.respond "Welcome to REALMS " + event.message.author.mention+". Type **%realm** to view your realm."
end