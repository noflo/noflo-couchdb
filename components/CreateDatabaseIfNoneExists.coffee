noflo = require 'noflo'
connection = require '../lib/connection'
nano = require 'nano'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'url',
    datatype: 'string'
  c.outPorts.add 'url',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
  c.forwardBrackets =
    url: ['url', 'error']
  c.process (input, output) ->
    return unless input.hasData 'url'
    url = input.getData 'url'
    db = connection.parseUrl url
    server = nano db.server
    server.db.create db.database, (err, body) ->
      if err and err.error isnt 'file_exists'
        output.done err
        return
      output.sendDone
        url: url
    return
