
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

class ReadDocument extends CouchDbComponentBase
  constructor: ->
    super
    @pendingRequests = []

    @inPorts.in = new noflo.ArrayPort()
    @outPorts.out = new noflo.Port()

    # Add an event listener to the URL in-port that we inherit from CouchDbComponentBase
    @inPorts.url.on "data", (data) =>
      if @dbConnection?
        @loadObject doc for doc in @pendingRequests
      else
        @sendLog
          logLevel: "error"
          context: "Connecting to the CouchDB database at URL '#{data}'."
          problem: "Parent class CouchDbComponentBase didn't set up a connection."
          solution: "Refer the document with this context information to the software developer."

    @inPorts.in.on "data", (docID) =>
      if @dbConnection?
        @loadObject docID
      else
        @pendingRequests.push docID

  loadObject: (docID) ->
    @dbConnection.get docID, (err, document) =>
      if err?
        @sendLog
          logLevel: "error"
          context: "Reading document of ID #{docID} from CouchDB."
          problem: "The document was not found."
          solution: "Specify the correct document ID and check that another user did not delete the document."
      else
        @outPorts.out.send document if @outPorts.out.isAttached()

exports.getComponent = -> new ReadDocument

