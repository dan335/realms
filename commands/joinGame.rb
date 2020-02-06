def command_joinGame(event, mongo)

    users = mongo[:users]

    # check if user exists
    if users.find(:userId => event.message.author.id).count > 0
        event.respond "I already have a realm for you " + event.message.author.mention + ".  Cannot create another one."
        return
    end

    # save user to db
    users.insert_one({
        :userId => event.message.author.id,
        :username => event.message.author.username,
        :avatar_url => event.message.author.avatar_url,
        :mention => event.message.author.mention,
        :distinct => event.message.author.distinct,
        :discriminator => event.message.author.discriminator
    })

    event.respond "Welcome to REALMS " + event.message.author.mention
end