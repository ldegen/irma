parser = require '../lib/query-parser.pegjs'

module.exports = 
  parse: (input)->
    try
      parser.parse input
    catch e
      tokens = input.split /[\t\n\r ()]+/
      ['TERMS', tokens...]
