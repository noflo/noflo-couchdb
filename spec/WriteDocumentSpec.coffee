if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/WriteDocument"
  noflo = require "noflo"
  nock = require "nock"
  util = require "util"

describe "WriteDocument", ->
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

  describe "can write a document to the database", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .post("/noflo-test", {"type":"test message","seqNum":1})
        .reply(201, "{\"ok\":true,\"id\":\"16aa3b990c03ce590f4a2ce296eff8d6\",\"rev\":\"1-c7e9d5e777a88118ded086f9d55aa330\"}\n", { "x-couch-request-id": "e2732a15",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        location: "http://accountName.cloudant.com/noflo-test/16aa3b990c03ce590f4a2ce296eff8d6",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "95",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { type: "test message", seqNum: 1 }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send the document to the out port when done", ->
      chai.expect(outMessages).to.have.length(1)
      chai.expect(outMessages[0]).to.deep.equal
        id: "16aa3b990c03ce590f4a2ce296eff8d6",
        rev: "1-c7e9d5e777a88118ded086f9d55aa330",
        type: "test message",
        seqNum: 1

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

  describe "can write several documents to the database", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .post("/noflo-test", {"type":"test message","seqNum":1})
        .reply(201, "{\"ok\":true,\"id\":\"16aa3b990c03ce590f4a2ce296eff8d6\",\"rev\":\"1-c7e9d5e777a88118ded086f9d55aa330\"}\n", { "x-couch-request-id": "e2732a15",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        location: "http://accountName.cloudant.com/noflo-test/16aa3b990c03ce590f4a2ce296eff8d6",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "95",
        "cache-control": "must-revalidate" })
        .post("/noflo-test", {"type":"test message","seqNum":2})
        .reply(201, "{\"ok\":true,\"id\":\"e90b5d7344f95173c85a3bb9115d0555\",\"rev\":\"1-eed5caef6cd378232dd9da0a2a3f808d\"}\n", { "x-couch-request-id": "e2732a15",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        location: "http://accountName.cloudant.com/noflo-test/e90b5d7344f95173c85a3bb9115d0555",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "95",
        "cache-control": "must-revalidate" })
        .post("/noflo-test", {"type":"test message","seqNum":3})
        .reply(201, "{\"ok\":true,\"id\":\"07fca815ec22372153d694ba96428cc1\",\"rev\":\"1-a3903e08dfc2e4b32ce9af24d4278902\"}\n", { "x-couch-request-id": "e2732a15",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        location: "http://accountName.cloudant.com/noflo-test/07fca815ec22372153d694ba96428cc1",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "95",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { type: "test message", seqNum: 1 }
      inSocket.send { type: "test message", seqNum: 2 }
      inSocket.send { type: "test message", seqNum: 3 }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send many documents to the out port when done", ->
      chai.expect(outMessages).to.have.length(3)
      chai.expect(outMessages).to.deep.equal [
        { id: "16aa3b990c03ce590f4a2ce296eff8d6", rev: "1-c7e9d5e777a88118ded086f9d55aa330", type: "test message", seqNum: 1 },
        { id: "e90b5d7344f95173c85a3bb9115d0555", rev: "1-eed5caef6cd378232dd9da0a2a3f808d", type: "test message", seqNum: 2 },
        { id: "07fca815ec22372153d694ba96428cc1",  rev: "1-a3903e08dfc2e4b32ce9af24d4278902",  type: "test message", seqNum: 3 }
      ]

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

  describe "logs an error when appropriate", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .post("/noflo-test", {"type":"test message","seqNum":1})
        .reply(401, "{\"error\":\"unauthorized\",\"reason\":\"Name or password is incorrect\"}\n", { "x-couch-request-id": "3185aaa2",
        "www-authenticate": "Basic realm=\"Cloudant Private Database\"",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "66",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { type: "test message", seqNum: 1 }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should not send any message to the out port", ->
      chai.expect(outMessages).to.have.length(0)

    it "should log an error message", ->
      chai.expect(logOutMessages).to.have.length(1)
      chai.expect(logOutMessages[0]).to.have.property "logLevel", "error"
      chai.expect(logOutMessages[0]).to.have.property name for name in [ "context","problem","solution" ]
      chai.expect(logOutMessages[0]).to.have.deep.property "problem.error", "unauthorized"
