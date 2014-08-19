# Description
#   Open / close ports on security groups automatically in AWS based on a user's presence
#
# Dependencies:
#   "aws-sesame": "0.0.1"
#
# Configuration:
#   HUBOT_AWS_REGION
#   HUBOT_AWS_KEY_ID
#   HUBOT_AWS_SECRET_KEY
#   HUBOT_AWS_SEC_RULES
#   HUBOT_ROOT_URL
#
# Commands:
#   hubot show firewall - Show all users who currently have access to AWS
#
# Notes:
#   HUBOT_AWS_SEC_RULES should be of the form (spaces are ignored):
#   <sec group id>: <port start>[ - <port end>][, <port start> - <port end>];
#
#   For instance, each of the following would work:
#   sg-123: 22
#   sg-123: 20 - 222
#   sg-123: 22; sg-456: 1-1600
#   sg-123: 10 - 20; sg-456: 30
#
#   HUBOT_ROOT_URL should be the root URL of an internet visible host.  This
#   is necessary so that a message can be sent to the client containing a link
#   to this bot's Hubot web server.
#
#   For instance, the following are valid values:
#   http://12.34.56.78
#   https://bothost.example.com
#   http://12.34.56.78:123
# 
# Author:
#   bmuller

UUID = require 'node-uuid', HTTP = require 'http', AWSSesame = require 'aws-sesame'

class Sesame
  constructor: (@robot) ->
    @aws = new AWSSesame
      sslEnabled: true
      region: process.env.HUBOT_AWS_REGION
      accessKeyId: process.env.HUBOT_AWS_KEY_ID
      secretAccessKey: process.env.HUBOT_AWS_SECRET_KEY
    @rules = @parseGroups(process.env.HUBOT_AWS_SEC_RULES or "")

  parseGroups: (parts) ->
    groups = []
    for group in parts.replace(new RegExp(" ", "g"), "").split ";"
      [sgid, ranges] = group.split(':')
      for range in ranges.split ","
        [lower, upper] = range.split "-"
        upper ?= lower
        groups.push [sgid, lower, upper]
    throw new Error("You must set the HUBOT_AWS_SEC_RULES environment variable.") unless groups.length
    console.log "Using the following rules in aws-sesame:"
    console.log groups
    groups

  close: (ip) ->
    for [sgid, lower, upper] in @rules
      @aws.revokeAccess sgid, 'tcp', ip, lower, upper, (result) ->
        if result
          console.log "closed ports #{lower} - #{upper} for #{ip} in #{sgid}"
        else
          console.log "issue while trying to close ports #{lower} - #{upper} for #{ip} in #{sgid}"

  open: (ip) ->
    for [sgid, lower, upper] in @rules
      @aws.grantAccess sgid, 'tcp', ip, lower, upper, (result) ->
        if result
          console.log "opened ports #{lower} - #{upper} for #{ip} in #{sgid}"
        else
          console.log "issue while trying to open ports #{lower} - #{upper} for #{ip} in #{sgid}"

  usersWithIp: (ip) ->
    (user for user in @robot.brain.users when user.ip is ip)


module.exports = (robot) ->
  sesame = new Sesame(robot)

  for env in "AWS_SEC_RULES AWS_REGION AWS_SECRET_KEY AWS_SEC_RULES ROOT_URL".split(' ')
    unless process.env["HUBOT_#{env}"]?
      throw new Error("You must set the HUBOT_#{env} environment variable.") 

  robot.router.get '/hubot/aws-gateway/:jid/:secret.jpg', (req, res) ->
    user = robot.brain.userForId req.params.jid
    if req.params.secret != user.ip_secret
      res.send 'invalid secret :('
      return
    user.ip_secret = UUID.v4()
    oldip = user.ip
    user.ip = req.headers['x-forwarded-for']?[0] or req.connection.remoteAddress
    if oldip isnt user.ip
      # close old connection if this is a new one for the user
      sesame.close oldip if oldip? and sesame.usersWithIp(oldip).length is 0
      # only open new connection if one doesn't already exist
      sesame.open user.ip unless sesame.usersWithIp(user.ip) > 1
    robot.send user: user, "You now have access to AWS from #{user.ip}"
    sendKitty robot, res

  robot.enter (msg) ->
    user = robot.brain.userForId msg.message.user.id
    user.ip_secret = UUID.v4()
    msg.send "#{process.env.HUBOT_ROOT_URL}/hubot/aws-gateway/#{msg.message.user.id}/#{user.ip_secret}.jpg"

  robot.leave (msg) ->
    user = robot.brain.userForId msg.message.user.id
    console.log "closing connection to #{user.ip}"
    oldip = user.ip
    user.ip = null
    # close access if this was the last user to be using that ip
    sesame.close oldip if oldip? and sesame.usersWithIp(oldip).length is 0

  robot.respond /show firewall/i, (msg) ->
    users = ("#{id} (#{user.ip})" for id, user of robot.brain.users() when user.ip?)
    msg.send "The following users have access:\n#{users.join('\n')}"


sendKitty = (robot, tres) ->
  q = v: '1.0', rsz: '8', q: 'kitten', safe: 'active', imgsz: 'small'
  url = 'http://ajax.googleapis.com/ajax/services/search/images'
  robot.http(url).query(q).get() (err, res, body) ->
    images = JSON.parse(body)
    images = images.responseData?.results
    if images?.length > 0
      image = images[ Math.floor(Math.random() * images.length) ]
      HTTP.get image.unescapedUrl, (res) ->
        tres.writeHead 200, 'Content-Type': res.headers['content-type'], 'Content-Length': res.headers['content-length']
        res.pipe(tres)
    else
      tres.send ""
