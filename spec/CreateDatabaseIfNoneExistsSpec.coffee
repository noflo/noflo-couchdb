chai = require 'chai'
noflo = require 'noflo'
nock = require 'nock'
path = require 'path'
baseDir = path.resolve __dirname, '../'

describe "CreateDatabaseIfNoneExists", ->
  newDbUrl = "https://adminUser:adminPass@accountName.cloudant.com/noflo-test"
  mockCouchDb = null
  component = null
  urlInSocket = null
  urlOutSocket = null
  errorSocket = null
  urlOutMessages = []
  errorMessages = []

  before (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'couchdb/CreateDatabaseIfNoneExists', (err, instance) ->
      return done err if err
      component = instance
      urlInSocket = noflo.internalSocket.createSocket()
      urlOutSocket = noflo.internalSocket.createSocket()
      errorSocket = noflo.internalSocket.createSocket()

      component.inPorts.url.attach urlInSocket
      component.outPorts.url.attach urlOutSocket
      component.outPorts.error.attach errorSocket

      urlOutSocket.on "data", (message) ->
        urlOutMessages.push message
      errorSocket.on "data", (message) ->
        errorMessages.push message
      done()

  describe "can create a database", ->
    before (done) ->
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
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should send the URL to the out port when done", ->
      chai.expect(urlOutMessages).to.deep.equal( [newDbUrl] )

  describe "will continue without error when the database already exists", ->
    before (done) ->
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
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed

    it "should have called CouchDB to create the database", ->
      mockCouchDb.done()

    it "should send the URL to the out port when done", ->
      chai.expect(urlOutMessages).to.deep.equal( [newDbUrl] )

  describe "will send an error other than file_exists", ->
    before (done) ->
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
      chai.expect(errorMessages).to.have.length(1)
      chai.expect(errorMessages[0]).to.have.property 'message'
