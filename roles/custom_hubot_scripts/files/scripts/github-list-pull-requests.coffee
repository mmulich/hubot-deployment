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

  getPullRequestComments: (repo, number, indentation, callback) ->
    console.log "getPullRequestComments #{repo}"
    @github.get "#{@urlApiBase}/repos/#{repo}/issues/#{number}/comments", (comments) ->
      # if second to last comment more than 8 days old and
      #    last comment less than 8 days old
      # display last comment
      previous = comments[comments.length - 2]
      last = comments[comments.length - 1]

      if not last
        return callback()

      # 8 days in milliseconds
      oneDay = 24 * 60 * 60 * 1000
      eightDays = 8 * oneDay

      lastUpdatedAt = moment last.updated_at
      msg = "#{indentation}**latest comment** <#{last.user.login}> #{last.body}"

      if moment() - lastUpdatedAt < eightDays
        if previous
          previousCreatedAt = moment previous.created_at
          if moment() - previousCreatedAt > eightDays
            return callback msg
        else
          return callback msg
      return callback()

  getPullRequest: (repo, pull, indentation, callback) ->
    createdAt = moment(pull.created_at).fromNow()
    updatedAt = moment(pull.updated_at).fromNow()
    lines = []
    lines.push "#{indentation}- \"#{pull.title}\" by #{pull.user.login} (created #{createdAt}, updated #{updatedAt}): #{pull.html_url}"
    this.getPullRequestComments repo, pull.number, "#{indentation}  ", (output) ->
      if output?
        lines.push output
      callback(lines.join '\n')

  getPullRequests: (repo, indentation, callback) ->
    console.log "getPullRequests #{repo}"
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
          else
            console.log "lines.length: #{lines.length} pulls.length: #{pulls.length}"

  listPullRequests: (printMessage) ->
    console.log "listPullRequests"
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
        else
          console.log "i: #{i} repo: #{repo} repos.length: #{@repos.length}"
      )

  printPullRequests: =>
    dayOfWeek = moment().day()
    if dayOfWeek >= 1 and dayOfWeek <= 5
      # only do this between monday and friday
      this.listPullRequests (message) =>
        console.log message
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


# # Fake stuff
# 
# fs = require 'fs'
# http = require 'https'
# url = require 'url'
# 
# 
# process = {
#   env: {
#     HUBOT_GITHUB_LIST_PR_REPOS: 'Connexions/cnx-archive',
#     HUBOT_GITHUB_LIST_PR_TIME: '09:25',
#     HUBOT_GITHUB_LIST_PR_ROOM: 'sprint@conference.jabber.cnx.org'
#   }
# }
# 
# 
# # Replace "@github = require('github')(@robot)" with "@github = new FakeGithub"
# class FakeGithub
#   get: (uri, callback) ->
#     console.log "FakeGithub.get #{uri}"
#     urlOptions = url.parse(uri)
#     urlOptions['headers'] = {'user-agent': 'node.js'}
#     http.get urlOptions, (response) ->
#       str = ''
#       response.on 'data', (chunk) ->
#         str += chunk
#       response.on 'end', ->
#         callback JSON.parse(str)
# 
# 
# class FakeRobot
#   messageRoom: (room, message) ->
#     console.log "messageRoom #{room} #{message}"
# 
# 
# PullRequestLister.prototype.run = ->
#     time = moment().hour(@hour).minute(@minute).second(0)
#     setTimeout this.printPullRequests, 0
# 
# 
# module.exports(new FakeRobot)
