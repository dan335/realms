def command_leaveGame(event, mongo)

    users = mongo[:users]

    # check if user exists
    if users.find(:discordId => event.message.author.id).count > 0

        users.delete_one(:discordId => event.message.author.id)
        mongo[:commands].delete_many(:discordId => event.message.author.id)
        
        event.respond event.message.author.mention + "'s realm has been destroyed."
    else
        event.respond "I can't find a realm for you " + event.message.author.mention + ".  Use __%joinGame__ to create one."
    end
end