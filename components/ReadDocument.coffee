noflo = require 'noflo'
connection = require '../lib/connection'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'in',
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
  c.process (input, output) ->
    return unless input.hasData 'in', 'url'
    [docId, url] = input.getData 'in', 'url'
    db = connection.connect url
    db.get docId, (err, document) ->
      return output.done err if err
      output.sendDone
        out: document
    return
