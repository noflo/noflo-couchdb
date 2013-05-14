if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/ReadDocument"
  noflo = require "noflo"
  nock = require "nock"
  util = require "util"

describe "ReadDocument", ->
  @timeout 5000  # Dear mocha, don't timeout tests that take less than 5 seconds. Kthxbai
  couchDbUrl = "https://adminUser:adminPass@accountName.cloudant.com/noflo-test"
  mockCouchDb = null
  component = null
  urlInSocket = null
  inSocket = null
  outSocket = null
  logOutSocket = null
  outMessages = []
  logOutMessages = []

  before ->
    component = componentModule.getComponent()
    urlInSocket = noflo.internalSocket.createSocket()
    inSocket = noflo.internalSocket.createSocket()
    outSocket = noflo.internalSocket.createSocket()
    logOutSocket = noflo.internalSocket.createSocket()

    component.inPorts.url.attach urlInSocket
    component.inPorts.in.attach inSocket
    component.outPorts.out.attach outSocket
    component.outPorts.log.attach logOutSocket

    # Listen for messages on the out and log ports.  Add the messages to an array for later inspection.
    logOutSocket.on "data", (message) ->
      logOutMessages.push message
      # console.log util.inspect message, 4, true, true  # uncomment this line if you want to see log messages as they arrive.

    outSocket.on "data", (message) ->
      outMessages.push message

  describe "can read a document that does exist in the database", ->
    before (done) ->
      logOutMessages.length = 0
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
      chai.expect(logOutMessages).to.have.length(0)

  describe "logs an error when a document does not exist in the database", ->
    before (done) ->
      logOutMessages.length = 0
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
      chai.expect(logOutMessages).to.have.length(1)
      chai.expect(logOutMessages[0]).to.have.property "logLevel", "error"
      for name in [ "context","problem","solution" ]
        chai.expect(logOutMessages[0]).to.have.property name
      chai.expect(logOutMessages[0]).to.have.deep.property "problem.error", "not_found"
