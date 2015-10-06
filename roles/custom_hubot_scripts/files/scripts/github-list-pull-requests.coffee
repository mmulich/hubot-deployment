# Description:
#   List all pending pull requests that are older than X number of days
#
# Dependencies:
#   "moment": ""
#
# Configuration:
#   HUBOT_GITHUB_LIST_PR_REPOS (e.g. "Connexions/webview,Connexions/cnx-archive")
#   HUBOT_GITHUB_LIST_PR_TIME (e.g. "09:25", has to be in the same timezone as the server)
#
# Comands:
#   None
#
# Authors:
#   karenc

moment = require('moment')

class PullRequestLister
  constructor: (@robot, @time, @repos, @room) ->
    @github = require('githubot')(@robot)
    unless (@urlApiBase = process.env.HUBOT_GITHUB_API)?
      @urlApiBase = 'https://api.github.com'
    [@hour, @minute] = @time.split ':'

  calculateTimeout: (time) ->
    now = (new Date).getTime()
    time.valueOf() - now

  getPullRequest: (repo, pull, indentation, callback) ->
    createdAt = moment(pull.created_at).fromNow()
    updatedAt = moment(pull.updated_at).fromNow()
    callback "#{indentation}- \"#{pull.title}\" by #{pull.user.login} (created #{createdAt}, updated #{updatedAt}): #{pull.html_url}"

  getPullRequests: (repo, indentation, callback) ->
    @github.get "#{@urlApiBase}/repos/#{repo}/pulls", (pulls) =>
      lines = []
      lines.push "#{pulls.length} pull request(s) for #{repo}"
      if pulls.length == 0
        callback(lines.join '\n')

      for pull in pulls
        this.getPullRequest repo, pull, "#{indentation}  ", (output) ->
          lines.push output
          if lines.length - 1 == pulls.length
            callback(lines.join '\n')

  listPullRequests: (printMessage) ->
    lines = []
    i = 1
    for repo in @repos
      this.getPullRequests(repo, '  ', (msg) =>
        lines.push msg
        if i++ == @repos.length
          printMessage '********************************************************************************'
          for line in lines
            printMessage line
          printMessage '********************************************************************************'
      )

  printPullRequests: =>
    dayOfWeek = moment().day()
    if dayOfWeek >= 1 and dayOfWeek <= 5
      # only do this between monday and friday
      this.listPullRequests (message) =>
        @robot.messageRoom @room, message

    # set the next timeout
    time = moment().hour(@hour).minute(@minute).second(0)
    time.add 1, 'day'
    setTimeout this.printPullRequests, this.calculateTimeout(time)

  run: ->
    time = moment().hour(@hour).minute(@minute).second(0)
    if time < new Date
      time.add 1, 'day'
    setTimeout this.printPullRequests, this.calculateTimeout(time)


module.exports = (robot) ->
  repos = process.env.HUBOT_GITHUB_LIST_PR_REPOS.split ','
  time = process.env.HUBOT_GITHUB_LIST_PR_TIME
  room = process.env.HUBOT_GITHUB_LIST_PR_ROOM
  pullRequestLister = new PullRequestLister robot, time, repos, room
  pullRequestLister.run()
