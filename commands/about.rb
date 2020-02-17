def command_about(bot, event, mongo)
    str = "-] **ABOUT REALMS** [-\n"
    str += "\n"
    str += "Add REALMS to your Discord channel with <https://discordapp.com/oauth2/authorize?client_id=677394191013380116&&scope=bot>\n"
    str += "\n"
    str += "Check out the source code at <https://github.com/dan335/realms>\n"
    str += "\n"
    str += "#realms discord - <https://discord.gg/ggUNQbR>"
    event.respond str
end
