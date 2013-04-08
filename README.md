CouchDB components for NoFlo [![Build Status](https://secure.travis-ci.org/bergie/noflo-couchdb.png?branch=master)](https://travis-ci.org/bergie/noflo-couchdb)
=========================

This module provides CouchDB components for the [NoFlo](http://noflojs.org/) flow-based programming framework

Read a document example flow
----------------------------
Here is an example FBP flow configuration to read a document from a database.

    'https://username:password@server.cloudant.com/my-database-name' -> URL DbConn(couchdb/OpenDatabase)
    DbConn() CONNECTION -> CONNECTION DocReader(couchdb/ReadDocument)
    DocReader() OUT -> IN ConsoleLogger(Output)
    'your_couchdb_document_id_here' -> IN DocReader(couchdb/ReadDocument)

In this example I instantiated 3 components which I have called DbConn, DocReader and ConsoleLogger.  DbConn will run an instance of the couchdb/OpenDatabase component, DocReader will run an instance of the couchdb/ReadDocument component (both of which are defined in this package) and the ConsoleLogger which is defined in the main [NoFlo](http://noflojs.org/) package.

To begin with, I send a message on the DbConn component's URL port telling it where to find the CouchDB database I want to read from.  Then I send the document ID that I want to read from the database to the DocReader component.  The DbConn component will create a CouchDB connection object which it will give to the DocReader.  The DocReader will then try to read the document I have asked for from CouchDB and send the document to the ConsoleLogger which will print it out for us to see.
