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
    unless doc.designDocID
      output.done new Error 'Request must contain a document designDocID'
      return
    unless doc.viewName
      output.done new Error 'Request must contain a document viewName'
      return
    doc.params = {} unless doc.params
    db = connection.connect url
    db.view doc.designDocID, doc.viewName, doc.params, (err, result) ->
      return output.done err if err
      output.sendDone
        out: result
    return
