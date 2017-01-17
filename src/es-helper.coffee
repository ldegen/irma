module.exports = (settings)->
  ElasticSearch = require "elasticsearch"
  SearchSemantic = require "./search-semantic"
  Yaml = require "js-yaml"
  fs = require "fs"
  path = require "path"
  Promise = require "promise"

  loadYaml = (rel)-> (Yaml.safeLoad (fs.readFileSync (path.join __dirname, rel)))



  projection =  require "./result-projection"

  client = new ElasticSearch.Client
    host: "#{settings.host}:#{settings.port}"
    keepAlive: settings.keepAlive

  index = settings.index

  reset: (mappings)->
    client.indices.delete
      index: index
      ignore: 404
    .then -> client.indices.create
      index:index
    .then ->
      Promise.all (
        for type,body of mappings
          client.indices.putMapping
            index:index
            type:type
            body:body
      )

  create: (doc)->
    this.bulkCreate [doc]
  bulkCreate: (docs)->
    cmd= (d)->
      index:
        _type: d.type
        _id:d.id
    lines =docs.reduce ((p,c)->p.concat [cmd(c),c]), []
    client.bulk
      index: index
      body:lines
      refresh:true
  fetch: (id, type)->
    client.get
      index:index
      type:type ? settings.defaultType
      id:id
  search: (query,options)->
    type = options.type ? settings.defaultType
    p = projection(query,type,options)
    aggs={}
    for attr in (options.types[type]?.attributes ? []) when attr.aggregation?
      aggs[attr.name] = attr.aggregation()

    if options?.sorter?.aggregation?
      aggs["_offsets"] = options.sorter.aggregation()

    hlFields = {}
    for attr in (options?.types?[type]?.attributes ? []) when attr.highlight?
      hlFields[attr.name] = attr.highlight()
    semantic = SearchSemantic options
    suggest = {}
    for suggestion in (options?.types?[type]?.suggestions ? [])
      s = suggestion.build query, type
      suggest[suggestion.name] = s if s?

    body=
      query: semantic query, type
      sort:  options.sorter.sort()
      _source: p._source
      suggest: suggest
      highlight:
        fields: hlFields
      aggs: aggs

    searchReq=
      index:index
      type: type
      size: Math.min ( options?.limit ? settings.defaultLimit ? 20), settings.hardLimit ? 250
      from:options?.offset||0
      body:body
    console.log "searchReq",require("util").inspect searchReq,false, null if settings.debug
    client.search(searchReq)
      .then (resp)->
        console.log "resp", require("util").inspect resp,false,null if settings.debug
        resp
      .then p

  random: (query, options)->

    type = options.type ? settings.defaultType

    client.search(
      index:index
      type: type
      size: 1
      from: 0
      body: query: function_score:
        query: SearchSemantic(query,options)
        functions:[
          random_score: {}#seed: Date.now()
        ]
    ).then (resp)->
      resp.hits.hits[0]._source
