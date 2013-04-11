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

Write a document example flow
-----------------------------
    'https://username:password@server.cloudant.com/my-database-name' -> URL DbConn(couchdb/OpenDatabase)
    DbConn() CONNECTION -> CONNECTION DocWriter(couchdb/WriteDocument)
    DocWriter() OUT -> IN ConsoleLogger(Output)
    DocWriter() LOG -> IN ConsoleLogger(Output)
    Txt2Obj() OUT -> IN DocWriter(couchdb/WriteDocument)
    '{ "source": "from NoFlo", "how_awesome": "Really rather good." }' -> IN Txt2Obj(ParseJson)

There are 4 components in this example.  Like the document reading example above, I create a CouchDB connection using an OpenDatabase component and direct connections that it opens to a WriteDocument component which I have called DocWriter in this flow.  The DocWriter likes to work with JavaScript objects but I can only write text strings in this flow document.  For the purposes of this demo, I parse the input string into a Javascript object before sending it to the document writer, which will send the parsed document on to CouchDB.  The component I called Txt2Obj in this flow uses the ParseJson component that is defined in the main [NoFlo](http://noflojs.org/) package.

