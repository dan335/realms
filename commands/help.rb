def command_help(event, mongo)
    str = "-] **REALMS** [-\n"
    str += "\n"
    str += "__%joinGame__ - Join the game.\n"
    str += "__%leaveGame__ - Leave the game.\n"
    str += "__%about__ - About.\n"
    str += "\n"
    #str += "__%realm__ - Check on your realm.\n"
    #str += "__%buildFarm__ - Build a farm.\n"
    event.respond str
end