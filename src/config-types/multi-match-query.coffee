ConfigNode = require "../config-node"
defaultParser = require "../query-parser"
Transformer = require "./ast-transformer"
{isArray} = require "util"
module.exports = class MultiMatchQuery extends ConfigNode
  parse: (queryString)->
    parser = @_options.parser ? defaultParser
    parser.parse queryString

  transform: ( ast, attributes, query)->
    #
    # FIXME: We need to think this through again!
    #
    # The idea was probably this: Merging the usual three query components would
    # result in a boolean query:
    #
    # query:
    #   bool:
    #     should: [
    #       {... contributed by multi-match ...}
    #       {... contributed by implicit phrase match ...}
    #     ]
    #     filter: [
    #       { ... contribued by filter query ...}
    #     ]
    #
    # Here I probably thought "Wait a minute! We don't want the result to include
    # hits that only satisfy the filter criteria. We need to set
    # minimum_should_match to 1."
    #
    # But why not simply let the multi-match query contribute a MUST clause?
    #
    # And there I probably said: "Nope. Because we don't know exactly how other
    # query components (like the non-standard implicit phrase query) should behave.
    # Maybe they want to contribute hits that are not accepted by the standard multi-match?"
    #
    # Looking this today I have to admit: we simply don't know. The savest bet is for
    # an application to compose the query semantics from scratch, using the parts that
    # IRMa provides. This is the case that we should make as easy as possible rather than
    # trying to refine some speculative default.
    #
    # In any case: it is a terrible idea to use a (*hidden* !) default behaviour and then
    # inject it into the AST-Transformer. This is *completly wrong* and needs to be fixed!
    #

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


