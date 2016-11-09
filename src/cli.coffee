fs = require "fs"
path = require "path"
merge = require "deepmerge"
LoadYaml = require "./load-yaml"
minimist = require "minimist"
automist = require "automist"
bulk = require "bulk-require"
{isArray} = require "util"

toCamelCase = (x)->
  if typeof x is "string"
    x.replace /\W+(\w)/g, (_,c)->c.toUpperCase()
  else
    o={}
    o[toCamelCase key]=value for key,value of x
    o

readme = LoadYaml() path.resolve __dirname, "../README.yaml"
argv = toCamelCase minimist (process.argv.slice 2), automist readme
if argv.help
  process.stderr.write automist.help readme
  process.exit -1

configTypes = {}
if argv.configTypes?
  dirs = argv.configTypes
  if not isArray dirs
    dirs = [dirs]
  else
    dirs = dirs.slice().reverse()
  for dir in dirs
    configTypes[key] = value for key,value of bulk dir, '*'

loadYaml = LoadYaml configTypes
# load factory settings
settings = loadYaml (path.resolve __dirname, "../default-settings.yaml")

# super-impose files from the command line in reverse order
configFiles = argv._.slice().reverse()
for configFile in configFiles
  settings = merge settings,  loadYaml configFile

# process command-line overrides
if argv.listen?
  [hostname, portString] = argv.listen.split ':'
  portNumber = parseInt portString
  settings.host = hostName
  settings.port = portNumber
if argv.esHost?
  [hostName:portString] = argv.esHost.split ':'
  portNumber = parseInt portString
  settings.elasticSearch.host = hostName
  settings.elasticSearch.port = portNumber
if argv.esIndex?
  settings.elasticSearch.index = argv.esIndex

Server = require "./server"
Server(settings).start().done ->
  console.error "server listening on port #{settings.port}"
