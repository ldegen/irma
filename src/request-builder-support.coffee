
# This module is meant to provide the basic building blocks
# for a ES search request. The signature of each function should follow
# the pattern (searchRequest, settings, attributes/sorter/suggestions)
#
# The first argument, `searchRequest` describes the actual request.
# It should be an object which at least two properties:
#
#   - `query` is an object representing the url parameters of the original request
#
#   - `type` is a string, the name of a type described in the configuration.
#
# The second argument, `settings` contains the complete runtime configuration
# of this irma instance. It is used to lookup types and attributes and stuff.
#
# The remaining argument(s) are optional. If ommited, the values are derived from the
# first two arguments. The idea is to allow custom reqeust transformers full control
# over what attributes/sorters/suggesters are processed when and where and how.
#
module.exports.highlightFields = (searchRequest, settings, attributes0)->
  attributes = attributes0 ? settings?.types?[searchRequest.type]?.attributes ? []
  hlFields = {}
  for attr in attributes
    if attr.highlight?
      hlFields[attr.field] = attr.highlight()
    if attr.highlightSubfields?
      hlSubfields = attr.highlightSubfields()
      for subfield, hlSettings of hlSubfields
        hlFields[attr.field+"."+subfield] = hlSettings
  hlFields

module.exports.suggest = (request, settings, suggestions0)->
  {query, type} = request
  suggestions = (suggestions0 ? settings?.types?[type]?.suggestions ? [])
  result = {}
  for suggestion in suggestions
    s = suggestion.build query, request, settings
    result[suggestion.name] = s if s?
  result

module.exports.sort = ({query:{sort}={}, type}, settings, SortParser0)->
  SortParser = SortParser0 ? settings.SortParser ? require "./sort-parser"
  parse = SortParser settings.types?[type]?.sort ? {}
  sorter = parse(sort)
  sorter.sort()


module.exports.aggregations = (searchRequest, settings, attributes0, SortParser0)->
  {type=settings.defaultType, query:{sort}={}}=searchRequest
  SortParser = SortParser0 ? settings.SortParser ? require "./sort-parser"
  attributes = attributes0 ? (settings.types[type]?.attributes ? [])
  aggs={}
  for attr in attributes when attr.aggregation?
    aggs[attr.name] = attr.aggregation(searchRequest, settings, attributes, SortParser)

  parse = SortParser settings.types?[type]?.sort ? {}
  sorter = parse(sort)
  if sorter?.aggregation?
    aggs["_offsets"] = sorter.aggregation(searchRequest, settings, attributes, SortParser)
  aggs


module.exports.explain = ({query:{explain}={}}) ->
  'true' is explain

module.exports.type = ({type},{defaultType})->type ? defaultType

semantics = (searchRequest, settings, semantics0)->
  type = settings?.types[searchRequest.type]
  searchSemantics = semantics0 ? settings?.types[searchRequest.type]?.searchSemantics ? settings.searchSemantics

module.exports.fielddataFields = (searchRequest, settings, attributes, semantics0) ->
  searchSemantics = semantics(searchRequest, settings, semantics0)
  if module.exports.explain(searchRequest) then searchSemantics.apply(searchRequest, settings, attributes).fields

module.exports.query = (searchRequest, settings, attributes, semantics0) ->
  searchSemantics = semantics(searchRequest, settings, semantics0)
  searchSemantics.apply(searchRequest, settings, attributes)

module.exports.size = ({query:{limit}={}}={}, {defaultLimit=20, hardLimit=250})->
  Math.min (limit ? defaultLimit ), hardLimit

module.exports.from = ({query:{offset=0}={}}={})->
  offset
