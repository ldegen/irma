fs = require "fs"
path = require "path"
merge = require "deepmerge"
loadYaml = require "./load-yaml"
settings = loadYaml (path.resolve __dirname, "../default-settings.yaml")
console.log "argv", process.argv
GEPRIS_HOME = process.env.GEPRIS_HOME
configFile = if GEPRIS_HOME? then path.resolve GEPRIS_HOME, 'geprisapp-service', 'settings.yaml'
if GEPRIS_HOME? and (fs.existsSync configFile) and (fs.statSync configFile).isFile()
  settings = merge settings, loadYaml configFile

if process.argv.length > 2
  settings = merge settings,  JSON.parse(fs.readFileSync(process.argv[3]))

if settings.attributes?
  console.error """
    WARNING: The configuration key 'attributes:' is deprecated!
    We are now using type-specific settings like 

      types:
        project:
          attributes:
            ...

    For now, I will assume your attributes were for type 'project'.
    """
  settings.types = merge (settings.types ? {}), project:attributes:settings.attributes
  delete settings.attributes

settings.types = {} if not settings.types?

if settings.domainSpecificBehaviour?
  console.error """
    WARNING: The configuration key 'domainSpecificBehaviour:' is deprecated!
    We are now using type-specific settings like 

      types:
        project:
          domainSpecificBehaviour:
            ...

    I will try to interprete the old settings, but please update your configuration!
    """
  for key,value of settings.domainSpecificBehaviour
    settings.types[key] = merge (settings.types[key] ? {}), domainSpecificBehaviour:value

Server = require "./server"
Server(settings).start().done ->
  console.error "server listening on port #{settings.port}"
