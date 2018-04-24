ConfigNode = require "../config-node"
defaultParser = require "../query-parser"
Transformer = require "./ast-transformer"
{isArray} = require "util"
module.exports = class MultiMatchQuery extends ConfigNode
  parse: (queryString)->
    parser = @_options.parser ? defaultParser
    parser.parse queryString

  transform: ( ast, attributes, query)->
    transformer = @_options.transformer ? new Transformer
      postProcess:(body, {fieldNames})->
        if Object.keys(body).length is 0
          fields:fieldNames
        else
          fields:fieldNames
          query:bool:
            should:[body]
            minimum_should_match: 1
    transformer.transform ast, attributes, query

  create: (query, type, attributes0)->

    queryString =query.q
    attributes = attributes0 ? type.attributes ? []

    if queryString? and queryString.trim().length > 0
      ast = @parse queryString
    else
      ast = []
    @transform  ast, attributes, query


