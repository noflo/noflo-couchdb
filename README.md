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

