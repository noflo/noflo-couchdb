
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

class ReadDocumentAttachment extends CouchDbComponentBase
  constructor: ->
    super
    @pendingRequests = []

    @inPorts.in = new noflo.Port
    @outPorts.out = new noflo.Port

    @inPorts.url.on "data", (data) =>
      if @dbConnection?
        @readAttachment request for request in @pendingRequests
      else
        @sendLog
          logLevel: "error"
          context: "Connecting to the CouchDB database at URL '#{data}'."
          problem: "Parent class CouchDbComponentBase didn't set up a connection."
          solution: "Refer the document with this context information to the software developer."

    @inPorts.in.on "data", (requestMessage) =>
      if @dbConnection?
        @readAttachment requestMessage
      else
        @pendingRequests.push requestMessage

  readAttachment: (requestMessage) =>
    unless requestMessage.docID? and requestMessage.attachmentName?
      @sendLog
        logLevel: "error"
        context: "Received a request to read and attachment from CouchDB."
        problem: "The request must be a object that includes both a 'docID' and an 'attachmentName' field."
        solution: "Fix the format of the request to this component. e.g. { 'docID': 'abc123', 'attachmentName': 'rabbit.jpg' }"

    @dbConnection.attachment.get requestMessage.docID, requestMessage.attachmentName, (err, body, header) =>
      if err?
        @sendLog
          logLevel: "error"
          context: "Reading attachment named '#{requestMessage.attachmentName}' from document of ID #{requestMessage.docID} from CouchDB."
          problem: "The document was not found."
          solution: "Specify the correct document ID and check that another user did not delete the document."
      else
        requestMessage.data = body
        requestMessage.header = header
        @outPorts.out.send requestMessage if @outPorts.out.isAttached()



exports.getComponent = -> new ReadDocumentAttachment
