
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

class WriteDocument extends CouchDbComponentBase
  constructor: ->
    super
    @request = null
    @pendingRequests = []

    @inPorts.in = new noflo.Port()
    @outPorts.out = new noflo.Port()

    @inPorts.url.on "data", (data) =>
      if @dbConnection?
        @saveObject doc for doc in @pendingRequests
      else
        @sendLog
          logLevel: "error"
          context: "Connecting to the CouchDB database at URL '#{data}'."
          problem: "Parent class CouchDbComponentBase didn't set up a connection."
          solution: "Refer the document with this context information to the software developer."

    @inPorts.in.on "data", (doc) =>
      if @dbConnection
        @saveObject doc
      else
        @pendingRequests.push doc
        
    @inPorts.in.on "disconnect", =>
      return unless @outPorts.out.isAttached()
      for port in @inPorts.in
        return if port.isConnected()
      @outPorts.out.disconnect()

  saveObject: (object) =>
    @dbConnection.insert object, (err, response) =>
      if err?
        @sendLog
          logLevel: "error"
          context: "Writing a document to CouchDB."
          problem: response
          solution: "Resolve all conflicts and check that you have permission to insert a document into this database."
      else
        @outPorts.out.send object if @outPorts.out.isAttached()

exports.getComponent = -> new WriteDocument
