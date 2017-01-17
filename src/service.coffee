module.exports = (settings)->
  Promise = require "promise"
  Path = require "path"
  ESHelper = require "./es-helper"
  Express = require "express"
  SortParser = require "./sort-parser"
  morgan = require "morgan"
  proxy = require "express-http-proxy"
  errorHandler = require "errorhandler"
  cheerio = require "cheerio"

  bulk = require "bulk-require"

  es = ESHelper(settings.elasticSearch)
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



  service.get '/:type/search', jsonP ( (req)->
    options =
      offset: req.query.offset
      limit:req.query.limit
      sorter:sort(req.params.type,req.query)
      type:req.params.type
    
    options.types = settings.types

    #console.log "options", options
    es.search req.query, options
  )



  service.get '/:type/random', jsonP (req)->
    options =
      attributes: settings.types[req.params.type].attributes
      seed: req.query.seed ? Math.random()
      type: req.params.type

    es.random req.query, options

  service.get '/:type/:id' , jsonP( (req)->
    es.fetch(req.params.id,req.params.type).then (body)->
      body._source
  )


  sort = (type,query)->
    parse = SortParser settings.types?[type]?.sort ? {}
    parse query.sort

  #service.disable 'etag'
  service


