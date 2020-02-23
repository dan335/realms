def command_help(bot, event, mongo)
    str = "-] **REALMS HELP** [-\n"
    str += "\n"
    str += "**%commands** to see available commands.\n\n"

    str += "__OBJECTIVE__\n"
    str += "Build "+$settings[:buildings][:shrine][:max].to_s+" shrines to win the game.  Shines have no other purpose.\n"
    str += "\n"

    str += "__COLLECTING RESOURCES__ - There are two different ways to collect resources.  Farms and taxes.\n"

    str += "**FARMS** - Use **%build farm** to build a farm.  Farms take 10 minutes to build.  The resources each farm produce are random.  If you are not happy with the amount of resources a farm collects use **%destroy farm 1** to destroy your first farm then build another.  You can have up to "+$settings[:buildings][:farm][:max].to_s+" farms.\n"
    str += "\n"
    str += "**TAXES** - Taxes are collected from the citizens of your realm.  Everyone starts the game with "+$settings[:startingPopulation].to_s+" population.  If your happiness is above 50% then your population will go up.  Happiness goes up if your taxes are low.  32.5% tax rate is about 50% happiness.\n"
    
    str += "\n"
    str += "__ATTACKING__\n"
    str += "Hire soldiers with **%hire 5 footmen**.  Soldiers consume resources every 10 minutes.  Attack another realm with **%attack Danimal 5 footmen**.  If your army defeats the other realm then they will steal "+($settings[:battleWinnings]*100).round.to_s+"% of their resources.  If you lose an attack it wil negatively affect happiness for an hour.\n"

    str += "\n"
    str += "__OTHER INFO__\n"
    str += "The game updates every 10 minutes.  Gold collects "+($settings[:goldInterestRate]*100.0).to_s+"% interest."
    event.respond str
end



