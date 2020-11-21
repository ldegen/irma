{
  highlightFields,
  suggest, sort, aggregations,
  explain, size, from, ast, type,
  fielddataFields, explain, query
} = require "../request-builder-support"

{ ConfigNode } = require "@l.degener/irma-config"

module.exports = class SearchRequestBuilder extends ConfigNode
  transform: (searchRequest, settings)->
    semantics = @_options.searchSemantics
    attributes = @_options.attributes
    (_)->
      type: type(searchRequest, settings)
      size: size(searchRequest, settings)
      from: from(searchRequest, settings)
      #ast: ast(searchRequest, settings, semantics)
      body:
        fielddata_fields: fielddataFields(searchRequest, settings,attributes,semantics)
        explain: explain(searchRequest, settings)
        query: query(searchRequest, settings, attributes, semantics)
        sort: sort(searchRequest, settings)
        suggest: suggest(searchRequest, settings)
        highlight: fields: highlightFields(searchRequest,settings, attributes)
        aggs: aggregations(searchRequest, settings, attributes)

