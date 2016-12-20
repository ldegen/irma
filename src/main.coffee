path = require "path"
ConfigBuilder = require "./config-builder"
cli = require "./cli"
args = process.argv.slice 2
env = Server: require("./server"), stderr: process.stderr, stdout: process.stdout
IRMA_TYPE_PATH = process.env.IRMA_TYPE_PATH?.split(path.delimiter) ? []
ConfigBuilder()
  .typePath IRMA_TYPE_PATH...
  .bind cli args...
  .run env 

