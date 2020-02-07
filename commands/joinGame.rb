def command_joinGame(event, mongo)

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
        :avatar_url => event.message.author.avatar_url,
        :mention => event.message.author.mention,
        :distinct => event.message.author.distinct,
        :discriminator => event.message.author.discriminator,
        :wood => 0,
        :ore => 0,
        :wool => 0,
        :clay => 0,
        :createdAt => Time.now
    })

    event.respond "Welcome to REALMS " + event.message.author.mention
end