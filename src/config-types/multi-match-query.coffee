{ ConfigNode } = require "@l.degener/irma-config"
defaultParser = require "../query-parser"
Transformer = require "./ast-transformer"
{isArray} = require "util"
module.exports = class MultiMatchQuery extends ConfigNode

  dependencies: ->io:['/','io']

  init: ({io})->
    #FIXME: issue a deprecation warning if a custom transformer is used.
    if @_options.transformer?
      throw new Error """
        ERROR:  multi-match-query: overriding the default AST transformer is not possible any more.
                The AST-Transformer is not considered public API and will be removed.
                All reasonyble settings of the transformer can be accessed through the
                multi-match-query settings instead.  If you need to go beyond that, consider
                writing your own custom query.
        """
    if @_options.postProcess? or @_options.postprocess?
      throw new Error """
        ERROR:  Don't try to add a post-processing step here! Do it in a separate request filter.
        """
    _options = @_options


    createEsQuery= (query, type, attributes0)->

      parser = _options.parser ? defaultParser
      queryString =query.q
      attributes = attributes0 ? type.attributes ? []

      if queryString? and queryString.trim().length > 0
        ast = parser.parse queryString
      else
        ast = []

      transformer = _options.transformer ? new Transformer
        fields: _options.fields
        fieldQualifiers: _options.fieldQualifiers
        customize: _options.customize
        defaultOperator: _options.defaultOperator
      transformer.transform ast, attributes, query

    @create= (query, type, attributes)->
      body = createEsQuery query, type, attributes
      if Object.keys(body).length is 0 then {}
      else bool:must:[body]


    @apply= ({query, type:typeName}, settings, attributes)->
      type = settings?.types?[typeName]
      body = createEsQuery query, type, attributes

      if Object.keys(body).length is 0 then {match_all:{}}
      else body
