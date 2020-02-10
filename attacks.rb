def doAttack(mongo, army)

    # create returning army
    mongo[:armies].insert_one({
        :discordId => army[:discordId],
        :userId => army[:userId],
        :createdAt => Time.now,
        :arriveAt => Time.now + 1000,   # Todo: fix this
        :soldiers => army[:soldiers],
        :isAttacking => false    # false if army is returning from battle
    })
end


def returnToRealm(mongo, army)

    # add army back to user
    inc = {}
    army[:soldiers].each do |s|
        inc[s[:type].pluralize.to_sym] = s[:num]
    end

    mongo[:users].update_one({:_id => army[:userId]}, {'$inc' => inc})

    updateNetworthFor(mongo, army[:discordId])
end