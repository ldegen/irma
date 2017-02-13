module.exports = (settings)->
  Promise = require "bluebird"
  Path = require "path"
  ESHelper = require "./es-helper"
  Express = require "express"
  RequestParser = require "./request-parser"
  ResponseParser = require "./response-parser"
  DefaultView = require "./default-view"
  CsvView = require "./csv-view"
  toCsv = Promise.promisify require "csv-stringify"
  morgan = require "morgan"
  proxy = require "express-http-proxy"
  errorHandler = require "errorhandler"
  cheerio = require "cheerio"

  bulk = require "bulk-require"

  parseRequest = RequestParser settings
  parseResponseBody = ResponseParser settings
  defaultView = DefaultView settings
  csvView = CsvView settings
  es = ESHelper(settings)
  P = (handler)->(req,res)->
    Promise
      .resolve handler req
      .then (data)->res.send data
      .catch (err)->
        console.error "error",err.stack||err
        res
          .status(err.status)
          .send(err)


  jsonP = (f)->
    (req,res)->
      success = (obj)->
        res.json obj
      failure = (err)->
        console.error "error",err.stack||err
        console.error "error",err
        res.status(err.status).send err
      try
        Promise.resolve(f(req)).done success,failure
      catch err
        console.error "error",err.stack||err
        res.status(500).send err

  

  service = Express()
  service.set 'port', settings.port
  if settings.pretty
    service.set 'json spaces', 2

  for mountPoint, dir of settings.static
    console.log "mounting #{dir} at #{mountPoint}"
    service.use mountPoint, Express.static dir
    
  for mountPoint, {host, augment} of settings.proxy
    console.log "forwarding #{mountPoint} to #{host}"
    opts =
      preserveHostHdr: true
      forwardPath: (req, res)->
        path= req.originalUrl
        path
    if augment?
      opts.intercept=(rsp, data0, req,res, callback)->
        if rsp.headers["content-type"]?.startsWith "text/html"
          console.log "augmenting"
          $=cheerio.load data0.toString()
          for src in (augment.js ? [])
            $("body").last().append(
              $("<script>")
                .attr "src", src
            )
          for href in (augment.css ? [])
            $("head").last().append(
              $("<link>")
                .attr "type", "text/css"
                .attr "rel", "stylesheet"
                .attr "href", href
            )
          data = $.html()
        else
          data = data0
        callback null, data

    service.use mountPoint, proxy host, opts
  service.use '/_irma', Express.static( Path.join(__dirname, '..', 'static'))
  service.use morgan('dev')
  service.use errorHandler()
  service.get '/_irma', (req,res)->
    res.json
      apiVersion: require("../package.json").version



  service.get '/:type/search', (req, res)->
    options =
      query: req.query
      type: req.params.type

    view = if req.query.view == "csv" then csvView else defaultView
    es.search parseRequest options
      .then parseResponseBody options
      .then view options
      .then ({data, mimeType})->
        if mimeType?
          res.set 'Content-Type', mimeType 
          if mimeType == "text/csv"  
            toCsv data 
          else 
            data
        else data
      .then (data)->
        res.send data
      .catch (err)->
        res
          .status(err.status)
          .send(err)

  



  service.get '/:type/random', jsonP (req)->
    options =
      seed: req.query.seed ? Math.random()
      query: req.query
      type: req.params.type

    es.random options

  service.get '/:type/:id' , jsonP( (req)->
    es.fetch(req.params.id,req.params.type).then (body)->
      body._source
  )

  service


