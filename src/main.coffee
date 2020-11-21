path = require "path"
{ConfigBuilder} = require "@l.degener/irma-config"
cli = require "./cli"
defaults = require "./default-settings"
args = process.argv.slice 2
env = Server: require("./server")
IRMA_TYPE_PATH = process.env.IRMA_TYPE_PATH?.split(path.delimiter) ? []
ConfigBuilder(defaults)
  .typePath IRMA_TYPE_PATH...
  .bind cli args...
  .run env

