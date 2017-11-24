chai = require 'chai'
noflo = require 'noflo'
nock = require 'nock'
path = require 'path'
baseDir = path.resolve __dirname, '../'

describe "ReadDocumentAttachment", ->
  @timeout 5000  # Dear mocha, don"t timeout tests that take less than 5 seconds. Kthxbai
  couchDbUrl = "https://adminUser:adminPass@accountName.cloudant.com/noflo-test"
  mockCouchDb = null
  component = null
  urlInSocket = null
  inSocket = null
  outSocket = null
  errorSocket = null
  outMessages = []
  errorMessages = []
  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'couchdb/ReadDocumentAttachment', (err, instance) ->
      return done err if err
      component = instance
      urlInSocket = noflo.internalSocket.createSocket()
      inSocket = noflo.internalSocket.createSocket()
      outSocket = noflo.internalSocket.createSocket()
      errorSocket = noflo.internalSocket.createSocket()
      component.inPorts.url.attach urlInSocket
      component.inPorts.in.attach inSocket
      component.outPorts.out.attach outSocket
      component.outPorts.error.attach errorSocket
      errorSocket.on "data", (message) ->
        errorMessages.push message
      outSocket.on "data", (message) ->
        outMessages.push message
      done()

  describe "can read a document attachment that exists in the database", ->
    before (done) ->
      errorMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and the attachment text.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/a8561c6524f5b33082de2c78e4756f03/sentence.txt")
        .reply(200, "The quick brown fox jumps over the lazy dogs.", { server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        etag: "11-c742bc6357b7dfe2558e59d362774c9f",
        date: new Date(),
        "content-type": "text/plain",
        "content-length": "45",
        "cache-control": "must-revalidate",
        "accept-ranges": "none" })

      urlInSocket.send couchDbUrl
      inSocket.send { id: "a8561c6524f5b33082de2c78e4756f03", attachmentName: "sentence.txt" }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send the JSON document to the out port when done", ->
      chai.expect(outMessages).to.have.length(1)
      chai.expect(outMessages[0]).to.have.property "id", "a8561c6524f5b33082de2c78e4756f03"
      chai.expect(outMessages[0]).to.have.property "attachmentName", "sentence.txt"
      chai.expect(outMessages[0]).to.have.property "header"

    it "should not send a error message", ->
      chai.expect(errorMessages.length).to.equal 0

  describe "logs an error when a document does not exist in the database", ->
    before (done) ->
      errorMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/a8561c6524f5b33082de2c78e4756f03/sentence.wrong_extension")
        .reply(404, "{\"error\":\"not_found\",\"reason\":\"missing\"}\n", { server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "41",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { id: "a8561c6524f5b33082de2c78e4756f03", attachmentName: "sentence.wrong_extension" }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should not send any message to the out port", ->
      chai.expect(outMessages).to.eql []

    it "should log an error message", ->
      chai.expect(errorMessages).to.have.length(1)
      chai.expect(errorMessages[0]).to.have.property "message"
