def command_help(bot, event, mongo)
    str = "-] **REALMS HELP** [-\n"
    str += "\n"
    str += "**%commands** to see available commands.\n\n"

    str += "__OBJECTIVE__\n"
    str += "Build "+$settings[:buildings][:shrine][:max].to_s+" shrines to win the game.  Shines have no other purpose.\n"
    str += "\n"

    str += "__COLLECTING RESOURCES__ - There are two different ways to collect resources.  Farms and taxes.\n"

    str += "**FARMS** - Use **%build farm** to build a farm.  Farms take 10 minutes to build.  The resources each farm produce are random.  If you are not happy with the amount of resources a farm collects use **%destroy farm 1** to destroy your first farm then build another.  You can have up to "+$settings[:buildings][:farm][:max].to_s+" farms.  All farms can be built at the same time.\n"
    str += "\n"
    str += "**TAXES** - Taxes are collected from the citizens of your realm.  The higher your population and tax rate the more taxes you will get.\n"
    str += "\n"
    str += "**POPULATION** - Everyone starts the game with "+$settings[:startingPopulation].to_s+" population.  If your happiness is above 50% then your population will grow.  If it falls below 50% then population goes down.  Reputation can also increase your population.\n"
    str += "\n"
    str += "**HAPPINESS** - Taxes, reputation and how long ago you lost an attack all affect happiness.  Happiness goes up if your taxes are low.  32.5% tax rate is about 50% happiness.  A reputation below 50% makes happiness go down.  If you attack someone and lose then happiness will go down for "+($settings[:losingBattleAffectsHappinessFor].to_f / 60.0 / 60.0).round(1).to_s+" hours.\n"
    str += "\n"
    str += "**REPUTATION** - Reputation goes down if you attack a realm much smaller than yours.  Reputation slowly increases back to 50%.  Attacking someone and winning increases your reputation.  If you recently won an attack then your reputation can go higher than 50% which makes your population increase.\n"
    
    str += "\n"
    str += "__ATTACKING__\n"
    str += "Hire soldiers with **%hire 5 footmen**.  Soldiers consume resources every 10 minutes.  Soldiers are hired from your population.  Attack another realm with **%attack Danimal 5 footmen** or use **%realms** to see the players ranking by networth and use their rank instead of their name for example **%attack 4 5 footmen**.  If your army defeats the other realm then they will steal "+($settings[:battleWinnings]*100).round.to_s+"% of their resources.  If you lose an attack it wil negatively affect happiness for "+($settings[:losingBattleAffectsHappinessFor] / 60 / 60).round(1).to_s+" hours.  If you attack someone who is building a shrine with at least one catapult and win then the shrine will be destroyed.\n"

    str += "\n"
    str += "__OTHER INFO__\n"
    str += "The game updates every 10 minutes.  Gold collects "+(($settings[:goldInterestRate]*100.0).round(4)).to_s+"% interest."

    msgs = Discordrb.split_message(str)

    msgs.each do |msg|
        event.respond msg
    end
end



