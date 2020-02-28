ConfigNode = require "../config-node"
ElasticSearch = require "elasticsearch"
Yaml = require "js-yaml"
fs = require "fs"
path = require "path"
Promise = require "bluebird"
merge = require "deepmerge"

module.exports = class EsAdapter extends ConfigNode

  dependencies: ->
    io: ["/","io"]
    #FIXME: remove this dependency, we only need it to provide legacy api
    types: ["/", "types"]

  init: ({types, io})->

    {console} = io
    {debug: debugSettings, host, port, keepAlive, index:defaultIndex,defaultType} = @_options

    debug = (key, msg)->
      if (debugSettings is true) or (typeof debugSettings is "object") and debugSettings?[key]
        console.log key, msg


    client = @client = new ElasticSearch.Client
      host: "#{host}:#{port}"
      keepAlive: keepAlive

    @get= (req, settings) -> ({id, typeName = defaultType})->
      body =
        index:settings.types[typeName]?.index ? defaultIndex
        type:typeName
        id:id
      client.get body
    
    legacyFetch = (id, typeName) -> @get(null, {types})({id, typeName})
    
    Object.defineProperty this, "fetch",
      writeable: true
      configurable: true
      enumerable: true
      get: ->
        console.warn """
          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

          WARNING: es-helper.fetch(id, typeName) is deprecated and *will be removed*.

          You should use es-helper.get(request,settings)({id, typeName}) instead.
          Alternatively, you can use the build-in plugin `legacy-fetch` which will
          provide the legacy API.

          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        """
        delete @fetch
        @fetch = legacyFetch
        @fetch
      set: (customFetch)->
        delete @fetch
        @fetch = customFetch

    @search = (req, settings) -> (searchReq0)->
      typeName = searchReq0.type ? defaultType
      index = settings.types[typeName]?.index ? defaultIndex
      searchReq = merge searchReq0, index: index
      {body:{explain=false} = {}} = searchReq
      debug "searchReq", JSON.stringify searchReq, null , "  "
      client.search(searchReq)
        .then (resp)->
          debug "resp", JSON.stringify resp, null, "  "
          resp._request = searchReq if explain
          resp._ast = ast if explain
          resp

    @analyze = (req, settings) -> ({field, text, type:typeName=defaultType})->
      index = settings.types[typeName]?.index ? defaultIndex
      client.indices.analyze {index,text,field}

    @random = (req, settings) -> ({type:typeName=defaultType, query, seed=Date.now()})->
      index = settings.types[typeName]?.index ? defaultIndex
      client.search(
        index:index
        type: typeName
        size: 1
        from: 0
        body: query: function_score:
          query: query
          functions:[
            random_score: seed: seed
          ]
      ).then (resp)->
        resp.hits.hits[0]._source

