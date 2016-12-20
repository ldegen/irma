# IRMa - The Information Retreival Middleware (something with a)

[![Build Status](https://api.travis-ci.org/ldegen/irma.svg?branch=master "current build status in travis")](https://travis-ci.org/ldegen/irma)

IRMa starts a small HTTP-server that will do three things:

- provide a convenient API to clients to search an ElasticSearch Index 
- provide access to static assets
- proxy HTTP requests to third-party servers with the possibility to
  inject client code and stylesheets into HTML documents.

This README currently is a total mess, sorry about that.
We are still in the process of writing / translating documentation.
If you have questions, feel free to open an issue.


## Install

Nothing out of the ordinary. You can use `npm install -g irma` for a global install.
This gives you the `irma` CLI (see below), which is probably good enough to get you started.

I personally prefer to put all my configuration/assets in NPM package of its own and
add irma as a `devDependency`. I can then start it programmatically or continue to use
the CLI via `script`-entries in my `package.json`.



