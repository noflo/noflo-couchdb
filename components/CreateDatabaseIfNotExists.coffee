
noflo = require "noflo"
{ CouchDbComponentBase } = require "../lib/CouchDbComponentBase"

class CreateDatabaseIfNotExists extends CouchDbComponentBase
  constructor: ->
    super
    @outPorts.url = new noflo.ArrayPort()

    # Add an event listener to the URL in-port that we inherit from CouchDbComponentBase
    @inPorts.url.on "data", (data) =>
      if @dbConnection?
        @createDbIfItDoesntExistThenSendUrl data
      else
        @sendLog
          logLevel: "error"
          context: "Connecting to the CouchDB database at URL '#{data}'."
          problem: "Parent class CouchDbComponentBase didn't set up a connection."
          solution: "Refer the document with this context information to the software developer."

  createDbIfItDoesntExistThenSendUrl: (urlString) =>
    # Create the database if it doesn't exist but ignore the error if it exists already.
    @couchDbServer.db.create @databaseName, (err, body) =>
      if err? and err.error isnt "file_exists"
        @sendLog
          logLevel: "error"
          context: "Creating database #{@databaseName} on the CouchDB server at '#{@serverUrl}'."
          problem: err
          solution: "Request permission to create this database from the CouchDB server administrator or have this database created for you."
      else
        connection = @couchDbServer.use @databaseName
        @outPorts.url.send urlString
        @outPorts.url.disconnect()

exports.getComponent = -> new CreateDatabaseIfNotExists
