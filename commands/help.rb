def command_help(event, mongo)
    str = "-] **REALMS COMMANDS** [-\n"
    str += "\n"
    str += "**%joinGame** - Join the game.\n"
    str += "**%leaveGame** - Leave the game.\n"
    str += "**%about** - About REALMS.\n"
    str += "\n"
    str += "**%realm** - View your realm.\n"
    str += "**%realms <page number>** - View all of the realms in the land.  Page number is optional\n"
    str += "**%build farm** - Build a farm.\n"
    str += "**%destroy farm 1** - Destroy farm number 1.\n"
    str += "**%hire** - Hiring help.\n"
    str += "**%hire <number> footman** - Hire a footman\n"
    str += "**%attack** - Attacking help.\n"
    str += "**%attack Danimal 3 footman 2 archers** - Attack Danimal with 3 footman and 2 archers.  Name can be @name, %realms number or username. - **not finished**\n"
    str += "**%cancelAttack 1** - Return attacking army to your realm. - **not finished**\n"
    event.respond str
end