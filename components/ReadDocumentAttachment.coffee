
noflo = require "noflo"
{ LoggedComponent } = require "./LoggedComponent"

class ReadDocumentAttachment extends LoggedComponent
  constructor: ->
    super
    @connection = null
    @pendingRequests = []

    @inPorts =
      connection: new noflo.Port
      in: new noflo.Port
    @outPorts.out = new noflo.Port

    @inPorts.connection.on "data", (connectionMessage) =>
      @connection = connectionMessage
      @readAttachment request for request in @pendingRequests

    @inPorts.in.on "data", (requestMessage) =>
      if @connection
        @readAttachment requestMessage
      else
        @pendingRequests.push requestMessage

  readAttachment: (requestMessage) =>
    unless requestMessage.docID? and requestMessage.attachmentName?
      @sendLog
        type: "Error"
        context: "Received a request to read and attachment from CouchDB."
        problem: "The request must be a object that includes both a 'docID' and an 'attachmentName' field."
        solution: "Fix the format of the request to this component. e.g. { 'docID': 'abc123', 'attachmentName': 'rabbit.jpg' }"

    @connection.attachment.get requestMessage.docID, requestMessage.attachmentName, (err, body, header) =>
      if err?
        @sendLog
          type: "Error"
          context: "Reading attachment named '#{requestMessage.attachmentName}' from document of ID #{requestMessage.docID} from CouchDB."
          problem: "The document was not found."
          solution: "Specify the correct document ID and check that another user did not delete the document."
      else
        requestMessage.data = body
        requestMessage.header = header
        @outPorts.out.send requestMessage if @outPorts.out.isAttached()



exports.getComponent = -> new ReadDocumentAttachment
