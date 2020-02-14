def command_about(event, mongo)
    str = "-] **ABOUT REALMS** [-\n"
    str += "\n"
    str += "Add REALMS to your Discord channel with https://discordapp.com/oauth2/authorize?client_id=677394191013380116&&scope=bot\n"
    str += "Check out the source code at https://github.com/dan335/realms"
    event.respond str
end