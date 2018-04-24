# the job of the search semantic module is to create the actual elasticsearch query from the
# request query parameters.
#
# This module does not do much itself. Instead, it gathers a list of QueryBuilders from the
# configuration, passes them the current type and query and lets them construct the parts of 
# the elasticsearch query.
#
# The results of all query builders are merged and returned.
# 
ConfigNode = require "../config-node"
MultiMatchQuery = require "./multi-match-query"
FilterQuery = require "./filter-query"
Merger = require "../merger"
{isArray} = require "util"
merge = Merger customMerge: (lhs,rhs,pass)->
  if isArray(lhs) and isArray(rhs) 
    lhs.concat rhs
  else pass
module.exports = class SearchSemantics extends ConfigNode
  apply: ({query, type:typeName}, settings, attributes)->
    defaultQueryComponents = [
      new MultiMatchQuery()
      new FilterQuery()
    ]
     
    type = settings?.types[typeName]

    queryComponents = @_options?.queryComponents ? defaultQueryComponents
    reducer = @_options?.reducer ? (a,b)->merge(a,b)
    initialQuery = @_options?.initialQuery ? {}


    r = queryComponents
      .map (qc)->qc.create(query,type, attributes)
      .reduce reducer, (if typeof initialQuery is 'function' then initialQuery(query,type) else initialQuery)

    r
