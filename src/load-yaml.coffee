
Yaml = require "js-yaml"
bulk = require "bulk-require"
path = require "path"
fs = require "fs"
coffee = require "coffee-script"

ConfigTypes = bulk (path.resolve __dirname, 'config-types'), '*'

yamlTypes = for key,value of ConfigTypes
  new Yaml.Type "!"+key,
    kind: 'mapping'
    construct: ((Constructor)->
      (data)->
        new Constructor(data)
    )(value)

yamlTypes.push new Yaml.Type '!coffee',
  kind: 'scalar'
  construct: (sourceCode)->
    coffee.eval sourceCode, sandbox:require './sandbox'


SCHEMA = Yaml.Schema.create yamlTypes


loadYaml = (file)->
  Yaml.safeLoad (fs.readFileSync file), schema: SCHEMA

module.exports = loadYaml
