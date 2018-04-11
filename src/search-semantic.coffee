# the job of the search semantic module is to create the actual elasticsearch query from the
# request query parameters.
#
# This module does not do much itself. Instead, it gathers a list of QueryBuilders from the
# configuration, passes them the current type and query and lets them construct the parts of 
# the elasticsearch query.
#
# The results of all query builders are merged and returned.
# 
ConfigNode = require "./config-node"
MultiMatchQuery = require "./config-types/multi-match-query"
FilterQuery = require "./config-types/filter-query"
Merger = require "./merger"
merge = Merger()
module.exports = class SearchSemantics extends ConfigNode
  apply: ({query, type:typeName}, settings)->
    defaultQueryComponents = [
      new MultiMatchQuery()
      new FilterQuery()
    ]
     
    type = settings?.types[typeName]

    queryComponents = @queryComponents ? defaultQueryComponents

    mergeX = (a,b)->
      merge(a,b)

    r = queryComponents
      .map (qc)->qc.create(query,type)
      .reduce mergeX, {}

    r
