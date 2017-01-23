module.exports = (settings, parser = require("./query-parser"), Query = require('./multi-match-query'))-> 
  
  ({query,type})->
    #console.log "query",query
    attrs = settings?.types[type]?.attributes ? []
    filters = []
    queryFields = {}
    for attr in attrs when attr.query
      queryFields[attr.field] = attr.boost ? 1

    for attr in attrs  when attr.filter?
      value = query[attr?.name]
      if(value?)
        filters.push attr.filter(value)

    r=
      bool:
        filter: filters

    if query?.q? and query?.q?.trim() != ""
      ast = parser.parse query.q
      querySemantic = Query
        fields:queryFields
      r.bool.must = querySemantic ast

    r
