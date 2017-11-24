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
    unless doc.id
      output.done new Error 'Request must contain a document ID'
      return
    unless doc.attachmentName
      output.done new Error 'Request must contain a document attachmentName'
      return
    db = connection.connect url
    db.attachment.get doc.id, doc.attachmentName, (err, body, header) ->
      return output.done err if err
      doc.data = body
      doc.header = header
      output.sendDone
        out: doc
    return
