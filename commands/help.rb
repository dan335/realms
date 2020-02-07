def command_help(event, mongo)
    str = "-] **REALMS** [-\n"
    str += "\n"
    str += "__%joinGame__ - Join the game.\n"
    str += "__%leaveGame__ - Leave the game.\n"
    str += "__%about__ - About REALMS.\n"
    str += "\n"
    str += "__%realm__ - View your realm.\n"
    str += "__%build farm__ - Build a farm.\n"
    event.respond str
end