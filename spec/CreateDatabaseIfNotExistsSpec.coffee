if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  componentModule = require "../components/CreateDatabaseIfNotExists"
  noflo = require "noflo"
  nock = require "nock"

setupComponent = ->
  c = componentModule.getComponent()
  urlInSocket = noflo.internalSocket.createSocket()
  urlOutSocket = noflo.internalSocket.createSocket()
  logOutSocket = noflo.internalSocket.createSocket()

  c.inPorts.url.attach urlInSocket
  c.outPorts.url.attach urlOutSocket
  c.outPorts.log.attach logOutSocket

  { component: c, urlInSocket: urlInSocket, urlOutSocket: urlOutSocket, logOutSocket: logOutSocket, urlOutMessages: [], logOutMessages: [] }

describe 'CreateDatabaseIfNotExists can create a database', ->
  newDbUrl = "https://adminUser:adminPass@accountName.cloudant.com/noflo-test"
  testComponents = setupComponent()
  mockCouchDb = nock('https://accountName.cloudant.com:443')
    .put('/noflo-test')
    .reply(201, "{\"ok\":true}\n", { 'x-couch-request-id': '8d15ce7c',
    server: 'CouchDB/1.0.2 (Erlang OTP/R14B)',
    location: 'http://accountName.cloudant.com/noflo-test',
    date: new Date(),
    'content-type': 'application/json',
    'content-length': '12',
    'cache-control': 'must-revalidate' });

  before (done) ->
    testComponents.logOutSocket.on "data", (message) ->
      testComponents.logOutMessages.push message

    testComponents.urlOutSocket.on "data", (message) ->
      testComponents.urlOutMessages.push message

    testComponents.urlInSocket.send newDbUrl

    setTimeout done, 1500  # wait 1.5 seconds to be sure all messages have been processed, including any on the log out port.

  it 'should have called CouchDB to create the database', ->
    mockCouchDb.done()

  it 'should send the URL to the out port when done', ->
    chai.expect(testComponents.urlOutMessages).to.deep.equal( [newDbUrl] )

  it 'should not send a log message', ->
    chai.expect(testComponents.logOutMessages).to.have.length(0)

