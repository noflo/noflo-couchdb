if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/CreateDatabaseIfNoneExists"
  noflo = require "noflo"
  nock = require "nock"
  util = require "util"

describe "CreateDatabaseIfNotExists", ->
  @timeout 5000  # Dear mocha, don't timeout tests that take less than 5 seconds. Kthxbai
  newDbUrl = "https://adminUser:adminPass@accountName.cloudant.com/noflo-test"
  mockCouchDb = null
  component = null
  urlInSocket = null
  urlOutSocket = null
  logOutSocket = null
  urlOutMessages = []
  logOutMessages = []

  before ->
    component = componentModule.getComponent()
    urlInSocket = noflo.internalSocket.createSocket()
    urlOutSocket = noflo.internalSocket.createSocket()
    logOutSocket = noflo.internalSocket.createSocket()

    component.inPorts.url.attach urlInSocket
    component.outPorts.url.attach urlOutSocket
    component.outPorts.log.attach logOutSocket

    # Listen for messages on the out and url ports.  Add the messages to an array for later inspection.
    logOutSocket.on "data", (message) ->
      logOutMessages.push message
      # console.log util.inspect message, 4, true, true  # uncomment this line if you want to see log messages as they arrive.

    urlOutSocket.on "data", (message) ->
      urlOutMessages.push message

  describe "can create a database", ->
    before (done) ->
      logOutMessages.length = 0
      urlOutMessages.length = 0

      # Prepare the couchDB mock to respond with a "201: OK" response.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .put("/noflo-test")
        .reply(201, "{\"ok\":true}\n", { "x-couch-request-id": "8d15ce7c",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        location: "http://accountName.cloudant.com/noflo-test",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "12",
        "cache-control": "must-revalidate" })

      urlInSocket.send newDbUrl
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should send the URL to the out port when done", ->
      chai.expect(urlOutMessages).to.deep.equal( [newDbUrl] )

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

  describe "will continue without error when the database already exists", ->
    before (done) ->
      logOutMessages.length = 0
      urlOutMessages.length = 0

      # Prepare the couchDB mock to respond with a "412: File already exists" response.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .put("/noflo-test")
        .reply(412, "{\"error\":\"file_exists\",\"reason\":\"The database could not be created, the file already exists.\"}\n", { "x-couch-request-id": "c9e3adab",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "95",
        "cache-control": "must-revalidate" })

      urlInSocket.send newDbUrl
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should send the URL to the out port when done", ->
      chai.expect(urlOutMessages).to.deep.equal( [newDbUrl] )

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

  describe "will log an error other than file_exists", ->
    before (done) ->
      logOutMessages.length = 0
      urlOutMessages.length = 0

      # Prepare the couchDB mock to respond with a "401: Unauthorised error" response.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .put("/noflo-test")
        .reply(401, "{\"error\":\"unauthorized\",\"reason\":\"Name or password is incorrect\"}\n", { "x-couch-request-id": "3185aaa2",
        "www-authenticate": "Basic realm=\"Cloudant Private Database\"",
        server: "CouchDB/1.0.2 (Erlang OTP/R14B)",
        date: new Date(),
        "content-type": "application/json",
        "content-length": "66",
        "cache-control": "must-revalidate" })

      urlInSocket.send newDbUrl
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should not receive the URL to the out port", ->
      chai.expect(urlOutMessages).to.have.length(0)

    it "should receive an error message on the log port", ->
      chai.expect(logOutMessages).to.have.length(1)
      chai.expect(logOutMessages[0]).to.have.property "logLevel", "error"
      for name in [ "context","problem","solution" ]
        chai.expect(logOutMessages[0]).to.have.property name
