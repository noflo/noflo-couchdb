nano = require 'nano'
url = require 'url'

exports.parseUrl = (dbUrl) ->
  databaseUrl = url.parse dbUrl
  database = databaseUrl.pathname.replace /^\//, ''
  databaseUrl.pathname = ''
  server = url.format databaseUrl
  result =
    database: database
    server: server
  return result

exports.connect = (dbUrl) ->
  db = exports.parseUrl dbUrl
  server = nano db.server
  return server.use db.database
