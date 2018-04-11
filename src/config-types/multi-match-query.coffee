ConfigNode = require "../config-node"
defaultParser = require "../query-parser"
Transformer = require "./ast-transformer"
{isArray} = require "util"
module.exports = class MultiMatchQuery extends ConfigNode
  parse: (queryString)->
    parser = @_options.parser ? defaultParser
    parser.parse queryString

  transform: ( ast, type, query)->
    transformer = @_options.transformer ? new Transformer
      postProcess:(body, {fieldNames})->
        if Object.keys(body).length is 0
          fields:fieldNames
        else
          fields:fieldNames
          query:bool:must:body
    transformer.transform ast, type, query

  create: (query, type)->

    queryString =query.q

    if queryString? and queryString.trim().length > 0
      ast = @parse queryString
    else
      ast = []
    @transform  ast, type, query


