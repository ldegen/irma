{parse} = require "./query-parser"
unparse = require "./ast-unparse"
{rewrite} = require "./ast-rewrite-rules"
pretty = require "./ast-pretty"

rewriteInput = (input)->
  {value} = rewrite parse input
  console.log pretty value
  return unparse value
readline = require 'readline'
rli = readline.createInterface
  input: process.stdin
  output: process.stdout


rli.on 'line', (input)->
  console.log ">>> "+rewriteInput input


