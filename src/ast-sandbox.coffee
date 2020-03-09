{parse} = require "./query-parser"
unparse = require "./ast-unparse.coffee"
{rewrite} = require "./ast-rewrite-rules.coffee"


rewriteInput = (input)->
  {value} = rewrite parse input
  return unparse value
readline = require 'readline'
rli = readline.createInterface
  input: process.stdin
  output: process.stdout


rli.on 'line', (input)->
  console.log ">>> "+rewriteInput input


