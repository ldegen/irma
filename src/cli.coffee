fs = require "fs"
path = require "path"
merge = require "deepmerge"
minimist = require "minimist"
Automist = require "automist"
LoadYaml = require "./load-yaml"
ConfigLoader = require "./config-loader"
{isArray} = require "util"

require "coffee-script/register"

module.exports = (proc = process)->
  toCamelCase = (x)->
    if typeof x is "string"
      x.replace /\W+(\w)/g, (_,c)->c.toUpperCase()
    else
      o={}
      o[toCamelCase key]=value for key,value of x
      o

  readme = LoadYaml() path.resolve __dirname, "../README.yaml"
  automist = Automist readme
  argv = toCamelCase minimist (proc.argv.slice 2), automist.options()
  if argv.help
    proc.stderr.write automist.help()
    proc.exit -1
  else if argv.manpage
    proc.stdout.write automist.manpage()
    proc.exit 0

  else
    configs = argv._
      .slice()
      .reverse()
      .map ConfigLoader argv.configTypes
    # process command-line overrides
    if argv.listen?
      [hostname, portString] = argv.listen.split ':'
      portNumber = parseInt portString
      configs.push host:hostName, port:portNumber
    if argv.esHost?
      [hostName:portString] = argv.esHost.split ':'
      portNumber = parseInt portString
      configs.push elasticSearch: host: hostName , port: portNumber
    if argv.esIndex?
      configs.push elasticSearch: index: esIndex

  configs

