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
    db = connection.connect url
    db.insert doc, (err, response) ->
      return output.done err if err
      doc.id = response.id unless doc.id
      doc.rev = response.rev
      output.sendDone
        out: doc
    return
