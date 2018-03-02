# the job of the search semantic module is to create the actual elasticsearch query from the
# request query parameters.
#
# This module does not do much itself. Instead, it gathers a list of QueryBuilders from the
# configuration, passes them the current type and query and lets them construct the parts of 
# the elasticsearch query.
#
# The results of all query builders are merged and returned.
# 
MultiMatchQuery = require "./config-types/multi-match-query"
FilterQuery = require "./config-types/filter-query"
Merger = require "./merger"
merge = Merger()
module.exports = (settings)->
  defaultQueryComponents = [
    new MultiMatchQuery()
    new FilterQuery()
  ]
  
  ({query,type:typeName})->
    type = settings?.types[typeName]

    queryComponents = type?.queryComponents ? settings?.queryComponents ? defaultQueryComponents

    mergeX = (a,b)->
      merge(a,b)

    r = queryComponents
      .map (qc)->qc.create(query,type)
      .reduce mergeX, {}

    r
