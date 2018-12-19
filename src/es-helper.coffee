module.exports = (settings)->
  ElasticSearch = require "elasticsearch"
  Yaml = require "js-yaml"
  fs = require "fs"
  path = require "path"
  Promise = require "bluebird"
  merge = require "deepmerge"

  {host, port, keepAlive, index:defaultIndex,defaultType} = settings.elasticSearch

  debug = (key, msg)->
    debugSettings = settings.elasticSearch.debug
    if (debugSettings is true) or (typeof debugSettings is "object") and debugSettings?[key]
      console.log key, msg


  client = new ElasticSearch.Client
    host: "#{host}:#{port}"
    keepAlive: keepAlive

  allIndices = (typeNames=[])->
    reducer = (accu, typeName)->
      index=settings.types[typeName]?.index ? defaultIndex
      if index in accu then accu else [accu..., index]

    typeNames.reduce(reducer, [])

  # mappings is assumed to be an object of the following form
  #
  # typeA: {...mapping for typeA}
  # typeB: ... etc.
  #

  reset: (mappings)->
    indices = allIndices Object.keys mappings

    client.indices.delete
      index: indices
      ignore: 404
    .then -> client.indices.create
      index:indices
    .then ->
      Promise.all (
        for typeName,body of mappings
          client.indices.putMapping
            index: settings.types[typeName]?.index ? defaultIndex
            type:typeName
            body:body
      )

  create: (doc)->
    this.bulkCreate [doc]

  bulkCreate: (docs)->
    cmd= (d)->
      index:
        _type: d.type ? defaultType
        _id:d.id,
        _index: settings.types[d.type ? defaultType]?.index ? defaultIndex
    lines =docs.reduce ((p,c)->p.concat [cmd(c),c]), []
    client.bulk
      index: defaultIndex
      body:lines
      refresh:true

  fetch: (id, typeName = defaultType)->
    client.get
      index:settings.types[typeName]?.index ? defaultIndex
      type:typeName
      id:id

  search: (searchReq0)->
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

  analyze: ({field, text, type:typeName=defaultType})->
    index = settings.types[typeName]?.index ? defaultIndex
    client.indices.analyze {index,text,field}

  random: ({type:typeName=defaultType, query, seed=Date.now()})->
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
  client: client
