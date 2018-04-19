module.exports = (settings)->
  Promise = require "bluebird"
  Path = require "path"
  ESHelper = require "./es-helper"
  Express = require "express"
  RequestParser = require "./request-parser"
  ResponseParser = require "./response-parser"
  morgan = require "morgan"
  proxy = require "express-http-proxy"
  errorHandler = require "errorhandler"
  cheerio = require "cheerio"

  bulk = require "bulk-require"
  parseQuery = require("./query-parser").parse
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

  for mountPoint, {host, augment, https, preserveHostHdr} of settings.proxy
    console.log "forwarding #{mountPoint} to #{host}"
    opts =
      forwardPath: (req, res)->
        path= req.originalUrl
        path
    opts.https=https if https?
    opts.preserveHostHdr = preserveHostHdr if preserveHostHdr?
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
  for mountPoint, mod of settings.dynamic
    service.get mountPoint, require(mod)
  service.use '/_irma', Express.static( Path.join(__dirname, '..', 'static'))
  service.use morgan('dev')
  service.use errorHandler()
  service.get '/_irma', (req,res)->
    res.json
      apiVersion: require("../package.json").version



  service.get '/_irma/analyze', jsonP (req)->
    es.analyze field:req.query.field, text:req.query.q
  service.get '/:type/search', (req, res)->
    viewName = req.query.view
    typeName = req.params.type
    options =
      query: req.query
      type: typeName
    if viewName?
      view = settings.types[typeName]?.views?[viewName] ? settings.views?[viewName]
      if not view?
        throw new Error("no such view: #{viewName}")
    else
      view = settings.views?.default ? settings.defaultView
    # FIXME: Ideally, this would be a pipeline consiting of two (or three?)
    # Phases: 
    #  - request phase transforms the information contained in the request
    #    into a search request that is passed to elasticsearch
    #  - response phase transforms the information contained in the response
    #    received from elasticsearch into the *our* response, i.e. what we want
    #    to send to our client.
    #
    # We are getting there, but we are not there yet.
    Promise.resolve options
      .then RequestParser settings, options
      .then es.search
      .then ResponseParser settings, options
      .then view.render settings, options
      .then sendResponse res
      .catch (err)->
        console.error (err.stack ? err)
        res
          .status(err.status ? 500)
          .send(err)


  sendResponse = (res)->({data, mimeType, headers={}})->
    res.set header, value for header,value of headers
    if mimeType?
      res.set 'Content-Type', mimeType
      encoder = settings.bodyEncoders?[mimeType]
      throw new Error("no encoder configured for #{mimeType}") unless encoder?
      encoder
        .encode data
        .then (encodedData)-> res.send encodedData
    else
      res.send data



  service.get '/:type/random', jsonP (req)->
    options =
      seed: req.query.seed ? Math.random()
      query: req.query
      type: req.params.type

    es.random options

  service.get '/:type/:id' , jsonP( (req)->
    tf = settings.types[req.params.type].documentTransform

    es.fetch(req.params.id,req.params.type).then (body)->
      if tf? and tf.transform? then tf.transform body._source else body._source
  )

  if settings.plugins?
    for plugin in settings.plugins
      if typeof plugin.install == 'function'
        plugin.install service
      else
        console.error 'function install missing in plugin'

  service


