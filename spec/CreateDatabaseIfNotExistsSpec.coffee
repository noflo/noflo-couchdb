if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/CreateDatabaseIfNotExists"
  noflo = require "noflo"
  nock = require "nock"

describe "CreateDatabaseIfNotExists", ->
  @timeout 5000  # Dear mocha, don't timeout tests that take less than 5 seconds.
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

    urlOutSocket.on "data", (message) ->
      urlOutMessages.push message

  describe "can create a database", ->
    before (done) ->
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

      setTimeout done, 1500  # wait 1.5 seconds to be sure all messages have been processed, including any on the log out port.

    after ->
      logOutMessages.length = 0
      urlOutMessages.length = 0

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should send the URL to the out port when done", ->
      chai.expect(urlOutMessages).to.deep.equal( [newDbUrl] )

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

