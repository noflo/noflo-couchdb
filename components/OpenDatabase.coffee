noflo = require "noflo"
nano = require "nano"
url = require "url"

class OpenDatabase extends noflo.Component
  constructor: ->
    @inPorts =
      url: new noflo.Port()
    @outPorts =
      connection: new noflo.ArrayPort()

    @inPorts.url.on "data", (data) =>
      try
        @parseConnectionString(data)
        @couchDbServer = nano(@serverUrl)
        @createDbIfItDoesntExistThenSendConnection()
      catch error
        if error.context?
          @sendLog error
        else
          @sendLog
            type: "Error"
            context: "Connecting to the CouchDB database at URL '#{data}'."
            problem: error
            solution: "Refer the document with this context information to the software developer."

  parseConnectionString: (connectionString) =>
    databaseUrl = try
      url.parse(connectionString)
    catch error
      throw {
        type: "Error"
        context: "Parsing the CouchDB database URL '#{data}' received on the configure port."
        problem: error
        solution: "Send a correctly formed URL to the configure port."
      }

    @databaseName = databaseUrl.pathname
    @databaseName = @databaseName.substring(1, @databaseName.length)
    @serverUrl = connectionString.substring(0, connectionString.length - @databaseName.length - 1)

  createDbIfItDoesntExistThenSendConnection: =>
    # Create the database if it doesn't exist but ignore the error if it exists already.
    @couchDbServer.db.create @databaseName, (err, body) =>
      if err? and err.error isnt "file_exists"
      else
        connection = @couchDbServer.use @databaseName
        @outPorts.connection.send connection
        @outPorts.connection.disconnect()

exports.getComponent = -> new OpenDatabase
