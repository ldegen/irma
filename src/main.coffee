ConfigBuilder = require "./config-builder"
cli = require "./cli"
args = process.argv.slice 2
env = Server: require("./server"), stderr: process.stderr, stdout: process.stdout

ConfigBuilder()
  .bind cli args...
  .run env 

