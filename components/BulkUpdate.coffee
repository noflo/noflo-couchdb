noflo = require 'noflo'
connection = require '../lib/connection'

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'in',
    datatype: 'object'
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
    [doc, url] = input.getData 'in', 'url'
    if not doc.docs or not Array.isArray doc.docs
      output.done new Error 'Request must be an object that includes a "docs" array of document changes'
      return
    db = connection.connect url
    db.bulk doc, (err, response) ->
      return output.done err if err
      output.sendDone
        out: response
    return
