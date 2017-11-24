noflo = require 'noflo'
connection = require '../lib/connection'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'follow',
    datatype: 'object'
  c.inPorts.add 'command',
    datatype: 'string'
  c.inPorts.add 'url',
    datatype: 'string'
    description: 'CouchDB URL'
    control: true
    scoped: false
  c.outPorts.add 'out',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
  c.feeds = {}
  c.tearDown = (callback) ->
    for scope, feed of c.feeds
      feed.stop
      feed._ctx.deactivate()
    c.feeds = {}
    do callback
  c.process (input, output, context) ->
    if input.hasData 'command'
      # Commands must wait until we're following
      return unless c.feeds[input.scope]
      cmd = input.getData 'command'
      switch cmd.toUpperCase()
        when 'STOP'
          c.feeds[input.scope].stop()
          c.feeds[input.scope]._ctx.deactivate()
          delete c.feeds[input.scope]
        when 'PAUSE'
          c.feeds[input.scope].pause()
        when 'RESUME'
          c.feeds[input.scope].resume()
        else
          output.done new Error "Command '#{cmd}' was not recognized"
          return
      output.done()
      return

    return unless input.hasData 'follow', 'url'
    [followOptions, url] = input.getData 'follow', 'url'
    db = connection.connect url
    c.feeds[input.scope] = db.follow followOptions
    c.feeds[input.scope]._ctx = context
    c.feeds[input.scope].on 'change', (msg) ->
      output.send
        out: msg
    return
