noflo = require "noflo"
nano = require "nano"
url = require "url"

{ LoggedComponent } = require "./LoggedComponent"

class OpenDatabase extends LoggedComponent
  constructor: ->
    super
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
        @sendLog
          context: "Creating database #{@databaseName} on the CouchDB server at '#{@serverUrl}'."
          problem: err
          solution: "Request permission to create this database from the CouchDB server administrator or have this database created for you."
      else
        connection = @couchDbServer.use @databaseName
        @outPorts.connection.send connection
        @outPorts.connection.disconnect()

exports.getComponent = -> new OpenDatabase
