def command_help(event, mongo)
    str = "-] **REALMS COMMANDS** [-\n"
    str += "\n"
    str += "**%joinGame** - Join the game.\n"
    str += "**%leaveGame** - Leave the game.\n"
    str += "**%about** - About REALMS.\n"
    str += "\n"
    str += "**%realm** - View your realm.\n"
    str += "**%realms** - View all the realms in the land. - **not finished**\n"
    str += "**%build farm** - Build a farm.\n"
    str += "**%destroy farm 1** - Destroy farm number 1.\n"
    str += "**%hire** - Hiring help.\n"
    str += "**%hire 1 footman** - Hire a footman - **not finished**\n"
    str += "**%attack Danimal 3 footman 2 archers** - Attack Danimal with 3 footman and 2 archers. - **not finished**\n"
    event.respond str
end