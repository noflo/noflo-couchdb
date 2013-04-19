noflo = require "noflo"
nano = require "nano"
url = require "url"

class exports.CouchDbComponentBase extends noflo.LoggingComponent
  constructor: ->
    super
    @inPorts =
      url: new noflo.Port()

    @inPorts.url.on "data", (data) =>
      try
        @parseConnectionString(data)
        @couchDbServer = nano(@serverUrl)
        @dbConnection = @couchDbServer.use @databaseName
      catch error
        if error.context?  # If the error is already well described...
          @sendLog error
        else
          @sendLog
            logLevel: "error"
            context: "Connecting to the CouchDB database at URL '#{data}'."
            problem: error
            solution: "Refer the document with this context information to the software developer."

  parseConnectionString: (connectionString) =>
    databaseUrl = try
      url.parse(connectionString)
    catch error
      throw {
        logLevel: "error"
        context: "Parsing the CouchDB database URL '#{data}' received on the configure port."
        problem: error
        solution: "Send a correctly formed URL to the configure port."
      }

    @databaseName = databaseUrl.pathname
    @databaseName = @databaseName.substring(1, @databaseName.length)  # remove the leading '/'
    @serverUrl = connectionString.substring(0, connectionString.length - @databaseName.length - 1)

