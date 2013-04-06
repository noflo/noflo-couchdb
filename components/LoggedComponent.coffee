

noflo = require "noflo"
util = require "util"

# This class should not be put into a flow. It is intended to be a parent class to real components.
class exports.LoggedComponent extends noflo.Component
  constructor: ->
    @outPorts =
      log: new noflo.Port()

  sendLog: (message) =>
    message.when = new Date
    message.source = this.constructor.name
    message.componentName = @name if @name?

    if @outPorts.log? and @outPorts.log.isAttached()
      @outPorts.log.send message
    else
      console.log util.inspect message, 4, true, true
 
