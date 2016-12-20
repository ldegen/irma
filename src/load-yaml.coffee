
Yaml = require "js-yaml"
bulk = require "bulk-require"
path = require "path"
fs = require "fs"
coffee = require "coffee-script"

module.exports = (additionalTypes={}, ignoreMissing=false)->
  ConfigTypes = bulk (path.resolve __dirname, 'config-types'), '*'

  ConfigTypes[key]=value for key,value of additionalTypes

  yamlTypes = for key,Constructor of ConfigTypes
    do (key, Constructor)->
      new Yaml.Type "!"+key,
        kind: 'mapping'
        construct: (data)->new Constructor data
        predicate: (obj)-> obj.constructor is Constructor
        represent: (obj)-> obj.options

  yamlTypes.push new Yaml.Type '!coffee',
    kind: 'scalar'
    construct: (sourceCode)->
      coffee.eval sourceCode, sandbox:require './sandbox'


  SCHEMA = Yaml.Schema.create Yaml.DEFAULT_SCHEMA, yamlTypes

  
  loadFile = (file)->
    content = undefined
    try
      content = fs.readFileSync file
    catch e
      if ignoreMissing and e.code == "ENOENT"
        return null
      else
        throw e
    parse content

  parse = (content)-> Yaml.safeLoad content, schema: SCHEMA
  unparse = (obj)-> Yaml.dump obj, schema: SCHEMA

  loadFile.parse = parse
  loadFile.unparse = unparse
    
  loadFile
