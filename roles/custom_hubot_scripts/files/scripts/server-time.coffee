# Description:
#   Show server time
#
# Commands:
#   hubot server time
#
# Authors:
#   karenc

module.exports = (robot) ->
  robot.respond /server time/, (res) ->
    res.reply "#{new Date}"
