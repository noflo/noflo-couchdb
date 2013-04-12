
noflo = require "noflo"
{ LoggedComponent } = require "./LoggedComponent"

class ReadDocumentAttachment extends LoggedComponent
  constructor: ->
    super
    @connection = null
    @document = null
    @attachment = null

    @inPorts =
      connection: new noflo.Port
      document: new noflo.Port
      attachment: new noflo.Port
    @outPorts =
      out: new noflo.Port
      @sendLog
        type: "Error"
        context: "Received a request to read and attachment from CouchDB."
        problem: "The request must be a object that includes both a 'docID' and an 'attachmentName' field."
        solution: "Fix the format of the request to this component. e.g. { 'docID': 'abc123', 'attachmentName': 'rabbit.jpg' }"

    @inPorts.connection.on "data", (data) =>
      @connection = data
      do @readAttachment if @document and @attachment

    @inPorts.document.on "data", (data) =>
      @document = data
      do @readAttachment if @connection and @attachment

    @inPorts.attachment.on "data", (data) =>
      @attachment = data
      do @readAttachment if @connection and @document

  getHeaders: ->
    headers =
      Host: @connection.uri.hostname

    if @connection.uri.auth
      hash = new Buffer(@connection.uri.auth, "ascii").toString "base64"
      headers.Authorization = "Basic #{hash}"

    return headers

  getRequest: (attachment, callback) ->
    options =
      host: @connection.uri.hostname
      method: "GET"
      path: "#{@connection.uri.pathname}/#{@document['_id']}/#{attachment}"
      port: @connection.uri.port
      headers: @getHeaders()

    req = @connection.uri.protocolHandler.request options, callback
    req.end()

  getAttachmentNameByIndex: (document, index) ->
    count = 0
    index = parseInt index
    for name, value of document['_attachments']
      return name if count is index
      count++
    return index

  getAttachmentName: (document, attachment) ->
    return attachment if isNaN attachment - 0
    return @getAttachmentNameByIndex document, attachment
        @sendLog
          type: "Error"
          context: "Reading attachment named '#{requestMessage.attachmentName}' from document of ID #{requestMessage.docID} from CouchDB."
          problem: "The document was not found."
          solution: "Specify the correct document ID and check that another user did not delete the document."

  readAttachment: ->
    attachment = @getAttachmentName @document, @attachment
    @getRequest attachment, (response) =>
      response.setEncoding "binary"
      body = ""
      port = @outPorts.out
      response.on "data", (chunk) ->
        body += chunk

      response.on "end", ->
        buffer = new Buffer body, "binary"
        port.send buffer
        do port.disconnect

exports.getComponent = -> new ReadDocumentAttachment
