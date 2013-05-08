
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

class GetChanges extends CouchDbComponentBase
  constructor: ->
    super

    @inPorts.follow = new noflo.Port()
    @inPorts.command = new noflo.Port()
    @outPorts.out = new noflo.Port()

    # Add an event listener to the URL in-port that we inherit from CouchDbComponentBase
    @inPorts.url.on "data", (data) =>
      @startFollowing() if @dbConnection? and @followOptions?

    # Since FOLLOW and URL messages might arrive in any order, check for both the options and connection before starting the feed.
    @inPorts.follow.on "data", (@followOptions) =>
      @startFollowing() if @dbConnection?

    @inPorts.command.on "data", (message) =>
      switch message.toUpperCase()
        when "STOP" then @feed.stop()
        when "PAUSE" then @feed.pause()
        when "RESUME" then @feed.resume()
        else @sendLog
          logLevel: "error"
          context: "Processing a message on the command port."
          problem: "Command '#{message}' was not recognised."
          solution: "The only valid commands are STOP, PAUSE or RESUME.  The commands are not case sensitive."

  startFollowing: =>
    @feed = @dbConnection.follow(@followOptions)

    @feed.on "change", (changeMessage) =>
      @outPorts.out.send changeMessage

    @feed.follow()

exports.getComponent = -> new GetChanges
