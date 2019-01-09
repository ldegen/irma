fs = require "fs"
path = require "path"
merge = require "deepmerge"
minimist = require "minimist"
LoadYaml = require "./load-yaml"
Automist = require "automist"
{unit, add, load, wrap} = ConfigBuilder = require "./config-builder"
{isArray} = require "util"

require "coffeescript/register"
module.exports = (args...)->

  toCamelCase = (x)->
    if typeof x is "string"
      x.replace /\W+(\w)/g, (_,c)->c.toUpperCase()
    else
      o={}
      o[toCamelCase key]=value for key,value of x
      o

  readme = LoadYaml() path.resolve __dirname, "../README.yaml"
  automist = Automist readme
  argv = toCamelCase minimist args, automist.options()

  printHelp = (cfg)->
    unit(cfg).then ({stderr})->stderr.write automist.help()
  generateManpage = (cfg)->
    unit(cfg).then ({stdout})->stdout.write automist.manpage()
  addDirsToTypePath = (cfg)->
    dirs = argv.configTypes ? []
    dirs =  [dirs] unless isArray dirs
    unit(cfg).typePath dirs.slice().reverse()...
  loadConfigFilesFromCommandLine = (cfg)->
    cb = argv._
      .slice()
      .reverse()
      .reduce ((cb,file)-> cb.load file), unit(cfg)
  processCommandLineOverrides = (cfg)->
    unit cfg
      .bind if argv.listen
          [hostName, portString] = argv.listen.split ':'
          portNumber = parseInt portString
          add host:hostName, port:portNumber
      .bind if argv.esHost?
          [hostName,portString] = argv.esHost.split ':'
          portNumber = parseInt portString
          add elasticSearch: host: hostName , port: portNumber
      .bind if argv.esIndex? 
          add elasticSearch: index: argv.esIndex 
  startServer = (cfg)->
    unit cfg
      .then ({Server}, settings)->
        Server(settings).start()
  printInfo = (cfg)->
    unit cfg
      .then ({stderr}, settings)->
        {host, port} = settings
        stderr.write "IRMa listening at http://#{host}:#{port}\n"
        settings
  installService = (cfg)->
    unit cfg
      .then ({stderr}, settings)->
        path = require "path"
        cleanSettings = {}
        cleanSettings[key] = value for key,value of settings when not key.startsWith '__'
        stderr.write LoadYaml(settings.__types).unparse cleanSettings
        s = settings.__typePath?.join path.delimiter
        stderr.write s if s?
        stderr.write "\n"
        settings
        
  if argv.help
    printHelp
  else if argv.manpage
    generateManpage
  else if argv.install then (cfg)->
    unit cfg
      .bind addDirsToTypePath
      .bind loadConfigFilesFromCommandLine
      .bind processCommandLineOverrides
      .bind installService
  else (cfg) -> 
    unit cfg
      .bind addDirsToTypePath
      .bind loadConfigFilesFromCommandLine
      .bind processCommandLineOverrides
      .bind startServer
      .bind printInfo
