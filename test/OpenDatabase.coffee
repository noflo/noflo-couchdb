readenv = require "../components/OpenDatabase"
socket = require('noflo').internalSocket

setupComponent = ->
  c = readenv.getComponent()
  url = socket.createSocket()
  connection = socket.createSocket()
  c.inPorts.url.attach url
  c.outPorts.connection.attach connection
  [c, url, connection]

exports['test opening a CouchDB connection'] = (test) ->
  test.expect 2
  [c, url, connection] = setupComponent()
  connection.once 'data', (data) ->
    test.equal typeof data, 'object'
    test.equal typeof data.get, 'function'
    test.done()
  url.send 'http://localhost:5984/myapp_test'
