
noflo = require "noflo"

class ReadDocument extends noflo.LoggingComponent
  constructor: ->
    @connection = null
    @pendingRequests = []

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
      if @connection
        @loadObject doc
      else
        @pendingRequests.push doc

  loadObject: (documentName) ->
    @connection.get documentName, (err, document) =>
      if err?
        @sendLog
          type: "Error"
          context: "Reading document of ID #{documentName} from CouchDB."
          problem: "The document was not found."
          solution: "Specify the correct document ID and check that another user did not delete the document."
      else
        @outPorts.out.send document if @outPorts.out.isAttached()

exports.getComponent = -> new ReadDocument
