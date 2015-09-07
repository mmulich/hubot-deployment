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
    unless (@url_api_base = process.env.HUBOT_GITHUB_API)?
      @url_api_base = 'https://api.github.com'
    [@hour, @minute] = @time.split ':'

  calculateTimeout: (time) ->
    now = (new Date).getTime()
    time.valueOf() - now

  getPullRequests: (repo, indentation, printMessage) ->
    @github.get "#{@url_api_base}/repos/#{repo}/pulls", (pulls) ->
      if pulls.length > 0
        printMessage "Pull requests for #{repo}"
      for pull in pulls
        createdAt = moment(pull.created_at).fromNow()
        updatedAt = moment(pull.updated_at).fromNow()
        printMessage "#{indentation}\"#{pull.title}\" by #{pull.user.login} (created #{createdAt}, updated #{updatedAt}): #{pull.html_url}"

  listPullRequests: (printMessage) ->
    lines = []
    printMessage '********************************************************************************'
    for repo in @repos
      this.getPullRequests(repo, '  ', printMessage)
    printMessage '********************************************************************************'

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
