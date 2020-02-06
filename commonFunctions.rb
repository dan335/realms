def isUserPlaying(mongo, userId)
    if mongo[:users].find(:userId => userId).count == 0
        return false
    else
        return true
    end
end