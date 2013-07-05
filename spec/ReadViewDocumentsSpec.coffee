if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/ReadViewDocuments"
  noflo = require "noflo"
  nock = require "nock"
  util = require "util"

describe "ReadViewDocuments", ->
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

  describe "can read a view that does exist in the database", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/_design/noflo_tests/_view/testDocs")
        .reply(200, "{\"total_rows\":3,\"offset\":0,\"rows\":[\r\n{\"id\":\"6acd0f19704c090cb51cd1c2beb04e2c\",\"key\":1,\"value\":{\"_id\":\"6acd0f19704c090cb51cd1c2beb04e2c\",\"_rev\":\"3-495ee0f828d06ad0d52a70003953f5c3\",\"type\":\"ViewTest\",\"messageID\":1}},\r\n{\"id\":\"a8561c6524f5b33082de2c78e4756f03\",\"key\":2,\"value\":{\"_id\":\"a8561c6524f5b33082de2c78e4756f03\",\"_rev\":\"2-1b9caf4d2ad154cc6f7fc255c015e57d\",\"type\":\"ViewTest\",\"messageID\":2}},\r\n{\"id\":\"8a761ddc142bb6b182e0f91b5a1e6272\",\"key\":3,\"value\":{\"_id\":\"8a761ddc142bb6b182e0f91b5a1e6272\",\"_rev\":\"17-46397db7956184091fa39d6575d63f74\",\"type\":\"ViewTest\",\"messageID\":3}}\r\n]}\n", { "x-couch-request-id": "1c103ebc",
        "transfer-encoding": "chunked",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        etag: "07fca815ec22372153d694ba967eb93c",
        date: new Date(),
        "content-type": "application/json",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { "designDocID": "noflo_tests", "viewName": "testDocs" }
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send the JSON document to the out port when done", ->
      chai.expect(outMessages).to.have.length(1)
      chai.expect(outMessages[0]).to.deep.equal
        total_rows: 3,
        offset: 0,
        rows: [
          {id:"6acd0f19704c090cb51cd1c2beb04e2c",key:1,value:{_id:"6acd0f19704c090cb51cd1c2beb04e2c",_rev:"3-495ee0f828d06ad0d52a70003953f5c3",type:"ViewTest",messageID:1}},
          {id:"a8561c6524f5b33082de2c78e4756f03",key:2,value:{_id:"a8561c6524f5b33082de2c78e4756f03",_rev:"2-1b9caf4d2ad154cc6f7fc255c015e57d",type:"ViewTest",messageID:2}},
          {id:"8a761ddc142bb6b182e0f91b5a1e6272",key:3,value:{_id:"8a761ddc142bb6b182e0f91b5a1e6272",_rev:"17-46397db7956184091fa39d6575d63f74",type:"ViewTest",messageID:3}}
        ]

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

  describe "logs an error when a document does not exist in the database", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "404: Not Found" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .get("/noflo-test/_design/rubbishName/_view/testDocs")
        .reply(404, "{\"error\":\"not_found\",\"reason\":\"missing\"}\n", { "x-couch-request-id": "76758fc2",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "41",
        "cache-control": "must-revalidate" })

      urlInSocket.send couchDbUrl
      inSocket.send { "designDocID": "rubbishName", "viewName": "testDocs" }
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
