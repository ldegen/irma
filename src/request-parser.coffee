
# TODO: these functions are all candidates for customable modules

highlightFields = (args, settings)->
  hlFields = {}
  for attr in (settings?.types?[args.type]?.attributes ? []) when attr.highlight?
    hlFields[attr.name] = attr.highlight()
  hlFields

suggest = ({query, type}, settings)->
  result = {}
  for suggestion in (settings?.types?[type]?.suggestions ? [])
    s = suggestion.build query
    result[suggestion.name] = s if s?
  result

sort = ({query:{sort}={}, type}, settings)->
  SortParser = settings.SortParser ? require "./sort-parser"
  parse = SortParser settings.types?[type]?.sort ? {}
  sorter = parse(sort)
  sorter.sort()
  
aggregations = ({type=settings.defaultType, query:{sort}={}}, settings)->
  SortParser = settings.SortParser ? require "./sort-parser"
  aggs={}
  for attr in (settings.types[type]?.attributes ? []) when attr.aggregation?
    aggs[attr.name] = attr.aggregation()

  parse = SortParser settings.types?[type]?.sort ? {}
  sorter = parse(sort)
  if sorter?.aggregation?
    aggs["_offsets"] = sorter.aggregation()
  aggs


module.exports = (settings, args)->
  searchSemantics = settings.searchSemantics
  queryParser = require "./query-parser"
  {query={}, type=settings.defaultType} = args
  explain = 'true' is query.explain
  limit = Math.min (query.limit ? settings.defaultLimit ? 20), (settings. hardLimit ? 250)
  offset = query.offset ? 0

  type: type
  size: limit
  from: offset
  ast: if explain then searchSemantics.apply(args, settings).ast else null
  body:
    fielddata_fields: if explain then searchSemantics.apply(args, settings).fields else []
    explain: explain
    query: searchSemantics.apply(args, settings).query
    sort: sort(args, settings)
    suggest: suggest(args, settings)
    highlight: fields: highlightFields(args,settings)
    aggs: aggregations(args, settings)
      
