noflo = require "noflo"

class ReadDocument extends noflo.Component
  constructor: ->
    @connection = null
    @data = []

    @inPorts =
      in: new noflo.ArrayPort()
      connection: new noflo.Port()
    @outPorts =
      out: new noflo.Port()

    @inPorts.connection.on "data", (connectionMessage) =>
      console.log "got a connection object."
      @connection = connectionMessage
      return unless @pendingRequests.length > 0
      @loadObject doc for doc in @pendingRequests

    @inPorts.in.on "data", (doc) =>
      console.log "got a read request."
      return @loadObject doc if @connection
      @pendingRequests.push doc

  loadObject: (documentName) ->
    @connection.get documentName, (err, document) =>
      if err?
      else
        @outPorts.out.send document if @outPorts.out.isAttached()

exports.getComponent = -> new ReadDocument
