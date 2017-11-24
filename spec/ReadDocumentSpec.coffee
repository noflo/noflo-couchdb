chai = require 'chai'
noflo = require 'noflo'
nock = require 'nock'
path = require 'path'
baseDir = path.resolve __dirname, '../'

describe "ReadDocument", ->
  @timeout 5000  # Dear mocha, don't timeout tests that take less than 5 seconds. Kthxbai
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
    loader.load 'couchdb/ReadDocument', (err, instance) ->
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

  describe "can read a document that does exist in the database", ->
    before (done) ->
      errorMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/a8561c6524f5b33082de2c78e4756f03")
        .reply(200, "{\"_id\":\"a8561c6524f5b33082de2c78e4756f03\",\"_rev\":\"2-1b9caf4d2ad154cc6f7fc255c015e57d\",\"type\":\"ViewTest\",\"messageID\":2}\n", { "x-couch-request-id": "5846e1c3",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        etag: "2-1b9caf4d2ad154cc6f7fc255c015e57d",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "119",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send "a8561c6524f5b33082de2c78e4756f03"
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send the JSON document to the out port when done", ->
      chai.expect(outMessages).to.have.length(1)
      chai.expect(outMessages[0]).to.deep.equal
        _id: 'a8561c6524f5b33082de2c78e4756f03',
        type: 'ViewTest',
        _rev: '2-1b9caf4d2ad154cc6f7fc255c015e57d',
        messageID: 2

    it "should not send a log message", ->
      chai.expect(errorMessages).to.have.length(0)

  describe "logs an error when a document does not exist in the database", ->
    before (done) ->
      errorMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/a8561c6524f5b33082de2c78e4756f")
        .reply(404, "{\"error\":\"not_found\",\"reason\":\"missing\"}\n", { "x-couch-request-id": "28b71e74",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "41",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send "a8561c6524f5b33082de2c78e4756f"
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should not send any message to the out port", ->
      chai.expect(outMessages).to.have.length(0)

    it "should log an error message", ->
      chai.expect(errorMessages).to.have.length(1)
      chai.expect(errorMessages[0]).to.have.property "message"
