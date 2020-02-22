require './commonFunctions.rb'
require './attacks.rb'
require 'active_support/core_ext/string'


def command_cancelattack(bot, event, mongo)
  # make sure user exists
  if !isUserPlaying(mongo, event.message.author.id)
      event.respond "I can't find your realm " + event.message.author.mention + ".  Use __%joinGame__ to create one."
      return
  end

  # get type
  msg = event.message.content
  msg.slice!(0)
  arr = msg.split

  # make sure it's the correct length
  if arr.length != 2
      event.respond "I don't understand that command "+event.message.author.mention+".  Try something like __%cancelAttack 1__."
      return
  end

  num = arr[1].to_i

  # make sure it's a number
  if num <= 0
    event.respond "I don't understand that command "+event.message.author.mention+".  Try something like __%cancelAttack 1__."
    return
  end

  count = 1
  army = nil
  mongo[:armies].find(:discordId => event.message.author.id).sort(:createdAt => 1).each do |a|
      if count == num
          army = a
      end
      count += 1
  end

  if army
    if army[:isAttacking]
      sendArmyToRealm(mongo, army, nil, Time.now - army[:createdAt])
      mongo[:armies].find(:_id => army[:_id]).delete_one
      event.respond "Your army is returning to your realm "+event.message.author.mention+"."
    else
      event.respond "Army "+num.to_s+" is already returning "+event.message.author.mention+"."
    end
  else
    event.respond "Count not find army "+num.to_s+" "+event.message.author.mention+"."
  end
end
