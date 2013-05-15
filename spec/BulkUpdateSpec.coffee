if typeof process is "object" and process.title is "node"
  chai = require "chai" unless chai
  componentModule = require "../components/BulkUpdate"
  noflo = require "noflo"
  nock = require "nock"
  util = require "util"

describe "BulkUpdate", ->
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

  describe "can send multiple updates to the database", ->
    before (done) ->
      logOutMessages.length = 0
      outMessages.length = 0

      # Prepare the couchDB mock to respond with a "200: OK" response and an JSON document.
      mockCouchDb = nock("https://accountName.cloudant.com:443")
        .post('/noflo-test/_bulk_docs', {"docs":[{"_id":"e90b5d7344f95173c85a3bb9115d0555","_rev":"1-eed5caef6cd378232dd9da0a2a3f808d","_deleted":true},{"_id":"9fb104a33609c077b904469572ba537b","_rev":"1-eed5caef6cd378232dd9da0a2a3f808d","_deleted":true},{"_id":"8a761ddc142bb6b182e0f91b5a1e6272","_rev":"17-46397db7956184091fa39d6575d63f74","newField":"some value"},{"_id":"blah","_rev":"13-c5642a2c2938cbd0228f60def0627d8a","existingField":"new value"}]})
        .reply(201, "[{\"id\":\"e90b5d7344f95173c85a3bb9115d0555\",\"rev\":\"2-2dec425e0bdc27edb38a3a013a0fe305\"},{\"id\":\"9fb104a33609c077b904469572ba537b\",\"rev\":\"2-2dec425e0bdc27edb38a3a013a0fe305\"},{\"id\":\"8a761ddc142bb6b182e0f91b5a1e6272\",\"rev\":\"18-dd894f75bc9c4bcde2ca0b6b287ae64f\"},{\"id\":\"blah\",\"rev\":\"14-60d6a9891b9e569601057b52dbb0e2ac\"}]\n", { 'x-couch-request-id': 'f7013890',
        server: 'CouchDB/1.0.2 (Erlang OTP/R14B)',
        date: 'Wed, 15 May 2013 19:31:50 GMT',
        'content-type': 'application/json',
        'content-length': '316',
        'cache-control': 'must-revalidate' })


      updateDoc = { docs: [
        { "_id": "e90b5d7344f95173c85a3bb9115d0555", "_rev": "1-eed5caef6cd378232dd9da0a2a3f808d", "_deleted": true},
        { "_id": "9fb104a33609c077b904469572ba537b", "_rev": "1-eed5caef6cd378232dd9da0a2a3f808d", "_deleted": true},
        { "_id": "8a761ddc142bb6b182e0f91b5a1e6272", "_rev": "17-46397db7956184091fa39d6575d63f74", "newField": "some value" },
        { "_id": "blah", "_rev": "13-c5642a2c2938cbd0228f60def0627d8a", "existingField": "new value" } ]
      }

      urlInSocket.send couchDbUrl
      inSocket.send updateDoc
      setTimeout done, 1000  # wait 1 second to be sure all messages have been processed, including any on the log out port.

    it "should have called CouchDB to read the document", ->
      mockCouchDb.done()

    it "should send the JSON document to the out port when done", ->
      chai.expect(outMessages).to.have.length(1)
      chai.expect(outMessages[0]).to.deep.equal [
        { id: 'e90b5d7344f95173c85a3bb9115d0555', rev: '2-2dec425e0bdc27edb38a3a013a0fe305' },
        { id: '9fb104a33609c077b904469572ba537b', rev: '2-2dec425e0bdc27edb38a3a013a0fe305' },
        { id: '8a761ddc142bb6b182e0f91b5a1e6272', rev: '18-dd894f75bc9c4bcde2ca0b6b287ae64f' },
        { id: 'blah', rev: '14-60d6a9891b9e569601057b52dbb0e2ac' },
      ]

    it "should not send a log message", ->
      chai.expect(logOutMessages).to.have.length(0)

