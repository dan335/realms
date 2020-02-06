def command_help(event, mongo)
    str = "-] **REALMS** [-\n"
    str += "\n"
    str += "__%joinGame__ - Join the game.\n"
    str += "__%leaveGame__ - Leave the game.\n"
    event.respond str
end