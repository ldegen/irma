module.exports = (settings)->
  SortParser = settings.SortParser ? require "./sort-parser"
  searchSemantic = settings.searchSemantic ? require("./search-semantic") settings
  
  funs =
    query: searchSemantic
    type: ({type=settings.defaultType})->type 
    from: ({query:{offset=0}})->offset
    size: ({query:{limit}})->
      Math.min (limit ? settings.defaultLimit ? 20), settings.hardLimit ? 250
    highlight: ({type})->
      hlFields = {}
      for attr in (settings?.types?[type]?.attributes ? []) when attr.highlight?
        hlFields[attr.name] = attr.highlight()
      fields: hlFields

    suggest: ({query, type})->
      suggest = {}
      for suggestion in (settings?.types?[type]?.suggestions ? [])
        s = suggestion.build query
        suggest[suggestion.name] = s if s?
      suggest

    sort: ({query:{sort}, type})->
      parse = SortParser settings.types?[type]?.sort ? {}
      sorter = parse(sort)
      sorter.sort()

    aggs: ({type=settings.defaultType, query:{sort}={}})->
      aggs={}
      for attr in (settings.types[type]?.attributes ? []) when attr.aggregation?
        aggs[attr.name] = attr.aggregation()

      parse = SortParser settings.types?[type]?.sort ? {}
      sorter = parse(sort)
      if sorter?.aggregation?
        aggs["_offsets"] = sorter.aggregation()
      aggs
  binder =  (options)->
    values = {}
    values[key] = fun options for key,fun of funs
    values
  binder[key] = fun for key,fun of funs
  binder
