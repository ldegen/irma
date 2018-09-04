{setWorldConstructor, After, AfterAll, BeforeAll} = require 'cucumber'

{Transform, TransformToMapping, TransformToBulk, BulkIndexSink, PutMappingSink} = require "tbob"
irma = require "../../src/index"

{transformSync: agg} = require "agg"

{Client} = require "elasticsearch"

Promise = require "bluebird"
request = require "request-promise"

fs = require "fs"
path = require "path"
tmp = require "tmp-promise"

writeFile = Promise.promisify fs.writeFile
mkdir = Promise.promisify fs.mkdir

# The world definition is static, i.e. all scenarios share the same
# factories.
tbobWorld = require "./tbob/world/rexi"

# TODO: this should probably be configurable as part of the scenario
# but for now it is static, too
indexSettings = require "./index-settings"

esUrl = "http://localhost:9200"
irmaUrl = "http://localhost:9990"
irmaOutFile = path.join __dirname, "../../irma.out"
irmaErrFile = path.join __dirname, "../../irma.err"
irmaOut = fs.createWriteStream irmaOutFile
irmaErr = fs.createWriteStream irmaErrFile
esClient = null

bulkOptions=
  defaults:
    id_attr:'id'
    type_attr:'type'

irmaServer = null
irmaPromise = null

setupTmpDir = ->
  tmp.dir unsafeCleanup: true
    .then (tmpDir)->
      pluginDir: path.join tmpDir, "plugins"
      configFile: path.join tmpDir, "irma.yaml"
      

startIrma = (configFileContent) ->
  
  # Note: we keep a reference to the server, so we can stop it later
  Server = (args...)->
    irmaServer = irma.Server args...

  # We also keep a reference to the startup promise. We need this during shutdown
  # to make sure that the startup process actually finnished
  irmaPromise = tmp.dir unsafeCleanup: true
    .then (tmpDir)->
      configFile = path.join tmpDir, "irma.yaml"
      pluginDir = path.join tmpDir, "plugins"
    
      Promise.all [
        writeFile configFile, configFileContent,
        mkdir pluginDir
      ]
      .then ->
        #TODO: pluginDir is currently just an empty directory. 
        irma.ConfigBuilder()
          .bind irma.Cli('-i', indexName, '-T', irmaPluginsDir, '-T', irmaSearchSemanticsDir, irmaConfigFile)
          .run
            Server: Server
            stderr: irmaErr
            stdout: irmaOut


stopIrma = ->
  irmaPromise?.finally ->
    irmaServer?.stop()
      .finally ->
        irmaOut.end()
        irmaErr.end()

convertInstitutionToSingletonGroup = (institution)->
  # if there is a `children` property, we assume the passed object
  # is in fact already a group, i.e. needs no conversion
  if institution.children?
    return institution 
  # otherwise, create a singleton group
  rootId: institution.id
  children: [institution]
BeforeAll ->
  esClient = new Client
    host: esUrl
    keepAlive: false

AfterAll ->
  esClient.close()

After ->
  stopIrma()

class CucumberWorld
  constructor: ()->
    @variable = 0
    @client = esClient

  resetIndex: (indexName, tbobTypeName) ->
    tbob = Transform tbobWorld,
      mode:'duplex'
    sink = new PutMappingSink @client,
      index:indexName
      reset:true
      settings: indexSettings
    tbob
      .pipe new TransformToMapping
      .pipe sink

    tbob.write [tbobTypeName]
    tbob.end()
    sink.promise

  putLookup: (data)->
    @lookup = data

  putInstitutions: (institutions0)->
    institutions=institutions0.map convertInstitutionToSingletonGroup
    tbob = Transform tbobWorld,
      mode:'duplex'
      options:
        lookup: @lookup
    sink = new BulkIndexSink @client,
      index: @index

    tbob
      .pipe new TransformToBulk bulkOptions
      .pipe sink

    tbob.write(["GroupES", institution]) for institution in institutions
    tbob.end()
    sink.promise

  search: (query)->
    @response = request
        uri: irmaUrl+"/group/search"
        qs: query
        resolveWithFullResponse: true
      .then (resp)->
        body: JSON.parse resp.body
        statusCode: resp.statusCode
        statusMessage: resp.statusMessage



    

setWorldConstructor CucumberWorld


