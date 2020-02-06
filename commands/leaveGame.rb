def command_leaveGame(event, mongo)

    users = mongo[:users]

    # check if user exists
    if users.find(:userId => event.message.author.id).count > 0
        users.delete_one(:userId => event.message.author.id)
        event.respond event.message.author.mention + "'s realm has been destroyed."
    else
        event.respond "I can't find a realm for you " + event.message.author.mention + ".  Use %joinGame to create one."
    end
end