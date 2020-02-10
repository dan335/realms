def isUserPlaying(mongo, discordId)
    if mongo[:users].find(:discordId => discordId).count == 0
        return false
    else
        return true
    end
end


# update networth for all players
def updateNetworth(mongo)
    bulk = []

    mongo[:users].find().each do |user|
        bulk << {:update_one => {
            :filter => {:_id => user[:_id]},
            :update => {'$set' => {:networth => calculateNetworthForUser(user)}}
        }}
    end

    mongo[:users].bulk_write bulk
end


def updateNetworthFor(mongo, discordId)
    user = mongo[:users].find(:discordId => discordId).first

    if user
        mongo[:users].update_one({:_id => user[:_id]}, {'$set' => calculateNetworthForUser(user)})
    end
end


def calculateNetworthForUser(user)
    net = user[:gold].to_i

    # resources
    $settings[:resourceTypes].each do |res|
        net += user[res.to_sym].to_i
    end

    # soldiers
    $settings[:soldierTypes].each do |st|
        $settings[:soldiers][st.to_sym][:cost].each do |c|
            net += user[st.pluralize.to_sym].to_i * c[:num]
        end
    end

    net
end