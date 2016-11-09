module.exports = (options, parser = require("./query-parser"), Query = require('./multi-match-query'))-> 
  
  (queryString,type)->
    #console.log "options",options
    #console.log "query",query
    attrs = options?.types[type]?.attributes ? []
    filters = []
    queryFields = {}
    for attr in attrs when attr.query
      queryFields[attr.field] = attr.boost ? 1

    for attr in attrs  when attr.filter?
      value = queryString[attr?.name]
      if(value?)
        filters.push attr.filter(value)

    r=
      bool:
        filter: filters

    if queryString?.q? and queryString?.q?.trim() != ""
      ast = parser.parse queryString.q
      querySemantic = Query
        fields:queryFields
      r.bool.must = querySemantic ast

    r
