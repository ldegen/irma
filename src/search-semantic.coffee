module.exports = (settings, parser = require("./query-parser"), Query = require('./multi-match-query'))-> 
  
  ({query,type})->
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
      fields: Object.keys(queryFields)
      query:
        bool:
          filter: filters

    if query?.q? and query?.q?.trim() != ""
      r.ast = parser.parse query.q
      querySemantic = Query
        fields:queryFields
      r.query.bool.must = querySemantic r.ast

    r
