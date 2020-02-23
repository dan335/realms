def command_help(bot, event, mongo)
    str = "-] **REALMS HELP** [-\n"
    str += "\n"
    str += "**%commands** to see available commands.\n\n"
    str += "Gold collects "+($settings[:goldInterestRate]*100.0).to_s+"% interest."
    event.respond str
end
