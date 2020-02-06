require './commonFunctions.rb'

def command_buildFarm(event, mongo)

    # make sure user exists
    if !isUserPlaying(mongo, event.message.author.id)
        event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
        return
    end

    # check how many farms user has already built
    numFarmsBeingBuilt = mongo[:promises].find({
        :userId => event.message.author.id,
        :type => "buildFarm"
    }).count

    numFarms = mongo[:farms].find({
        :userId => event.message.author.id
    }).count

    if numFarms + numFarmsBeingBuilt >= $settings[:maxFarms]
        event.respond "No more room for farms in your realm " + event.message.author.mention + ".  Destroy one to create another."
        return
    end

    # create command to build farm in the future
    mongo[:promises].insert_one({
        :userId => event.message.author.id,
        :type => "buildFarm",
        :createdAt => Time.now,
        :finishedAt => Time.now + $settings[:farmBuildSeconds]
    })

    event.respond "I'm building you a new farm " + event.message.author.mention + ".  It should be done in "+($settings[:farmBuildSeconds] / 60).round.to_s+" minutes.  Check it's progress with __%realm__"
end