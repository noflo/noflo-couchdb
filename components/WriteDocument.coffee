noflo = require "noflo"
{ LoggedComponent } = require "./LoggedComponent"

class WriteDocument extends LoggedComponent
  constructor: ->
    super
    @request = null
    @connection = null
    @pendingRequests = []

    @inPorts.in = new noflo.ArrayPort()
    @inPorts.connection = new noflo.Port()
    @outPorts =
      out: new noflo.Port()

    @inPorts.connection.on "data", (connectionMessage) =>
      @connection = connectionMessage
      return unless @pendingRequests.length > 0
      @saveObject doc for doc in @pendingRequests

    @inPorts.in.on "data", (doc) =>
      if @connection
        @saveObject doc 
      else
        @pendingRequests.push doc
        
    @inPorts.in.on "disconnect", =>
      return unless @outPorts.out.isAttached()
      for port in @inPorts.in
        return if port.isConnected()
      @outPorts.out.disconnect()

  saveObject: (object) =>
    @connection.insert object, (err, response) =>
      if err?
        @sendLog
          type: "Error"
          context: "Writing a document to CouchDB."
          problem: response
          solution: "Resolve all conflicts and check that you have permission to insert a document into this database."
      else
        @outPorts.out.send object if @outPorts.out.isAttached()

exports.getComponent = -> new WriteDocument
