module.exports = (settings)->
  ElasticSearch = require "elasticsearch"
  Yaml = require "js-yaml"
  fs = require "fs"
  path = require "path"
  Promise = require "bluebird"
  merge = require "deepmerge"

  {host, port, keepAlive, index,defaultType,debug} = settings.elasticSearch
  client = new ElasticSearch.Client
    host: "#{host}:#{port}"
    keepAlive: keepAlive

  index = index

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
      type:type ? defaultType
      id:id
  search: (searchReq0)->
    searchReq = merge searchReq0, index: index
    {body:{explain=false} = {}} = searchReq
    console.log "searchReq",require("util").inspect searchReq,false, null if debug
    client.search(searchReq)
      .then (resp)->
        console.log "resp", require("util").inspect resp,false,null if debug
        resp._request = searchReq if explain
        resp._ast = ast if explain
        resp

  analyze: ({field, text})->
    client.indices.analyze {index,text,field}
  random: (options)->

    client.search(
      index:index
      type: parser.type options
      size: 1
      from: 0
      body: query: function_score:
        query: parser.query options
        functions:[
          random_score: {}#seed: Date.now()
        ]
    ).then (resp)->
      resp.hits.hits[0]._source
