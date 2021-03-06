path = require "path"
{ConfigBuilder} = require "@l.degener/irma-config"
cli = require "./cli"
defaults = require "./default-settings"
configTypes = require "./config-types"
args = process.argv.slice 2
env = Server: require("./server")
IRMA_TYPE_PATH = process.env.IRMA_TYPE_PATH?.split(path.delimiter) ? []
ConfigBuilder(defaults)
  .types configTypes
  .typePath IRMA_TYPE_PATH...
  .bind cli args...
  .run env

