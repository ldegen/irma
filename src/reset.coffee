ESHelper = require "../src/es-helper"
WritableBulk = require('elasticsearch-streams').WritableBulk
EsClient = require('elasticsearch').Client
fs = require "fs"
path = require "path"
merge = require "deepmerge"

WritableBulk = require('elasticsearch-streams').WritableBulk
EsClient = require('elasticsearch').Client
JSONStream = require 'JSONStream'

loadYaml = require "./load-yaml"
settings = loadYaml (path.resolve __dirname, "../default-settings.yaml")
console.log "argv", process.argv
GEPRIS_HOME = process.env.GEPRIS_HOME
configFile = if GEPRIS_HOME? then path.resolve GEPRIS_HOME, 'geprisapp-service', 'settings.yaml'
if GEPRIS_HOME? and (fs.existsSync configFile) and (fs.statSync configFile).isFile()
  settings = merge settings, loadYaml configFile
argv = require('minimist')(process.argv.slice(2))

settings = merge settings,  loadYaml argv.c if argv.c?



ESHelper = require "./es-helper"
es = ESHelper settings.elasticSearch

createEsSink = (host, index, type) ->
  client = new EsClient(
    host: host
    keepAlive: false)

  bulkExec = (bulkCmds, callback) ->
    client.bulk {
      index: index
      type: type
      body: bulkCmds
    }, callback
    return

  ws = new WritableBulk(bulkExec)
  ws.on 'close', ->
    client.close()
    return
  ws
es
  .reset()
  .then ()->
    console.log "index resetted"
    if argv.b
      esHost = "http://#{settings.elasticSearch.host}:#{settings.elasticSearch.port}"
      sink = createEsSink esHost, settings.elasticSearch.index, 'project'
      console.log "uploading to",  esHost, settings.elasticSearch.index, 'project'
      fs
        .createReadStream argv.b
        .pipe JSONStream.parse()
        .pipe sink


