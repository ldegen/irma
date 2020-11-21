# the job of the search semantic module is to create the actual elasticsearch query from the
# request query parameters.
#
# This module does not do much itself. Instead, it gathers a list of QueryBuilders from the
# configuration, passes them the current type and query and lets them construct the parts of
# the elasticsearch query.
#
# The results of all query builders are merged and returned.
#
{ ConfigNode, Merger} = require "@l.degener/irma-config"
MultiMatchQuery = require "./multi-match-query"
FilterQuery = require "./filter-query"
{isArray} = require "util"
call = require "../call"
merge = Merger customMerge: (lhs,rhs,pass)->
  if isArray(lhs) and isArray(rhs)
    lhs.concat rhs
  else pass

warningsIssued = {}
module.exports = class SearchSemantics extends ConfigNode
  dependencies: ->io:["/","io"]
  init: ({io})->
    issueWarning = (msg)->
      unless warningsIssued[msg]
        warningsIssued[msg]= true
        io.console.warn msg
    issueWarning """
      WARNING: The type SearchSemantics (a.k.a. !search-semantics) is deprecated and will be removed.
               Have a look at CompositeQuery (a.k.a. !composite-query) instead.
    """
    normalizeOutput =(output)->
      if typeof output is "object" and Object.keys(output).length is 1 and output.query?
        issueWarning """
          WARNING: One of your query components outputs an extranous `query`-prefix.
                   This is not necessary anymore and will constitute an error in
                   future releases.
        """
        output = output.query
      output

    @apply = (req, settings, attributes)->
      {query, type:typeName}=req
      defaultQueryComponents = [
        new MultiMatchQuery()
        new FilterQuery()
      ]

      type = settings?.types[typeName]
      identity = (x)->x
      postprocess = @_options?.postprocess ? (o)->
        if Object.keys(o).length is 0 then {match_all:{}} else o
      queryComponents = @_options?.queryComponents ? defaultQueryComponents
      reducer = @_options?.reducer ? (a,b)->merge(a,b)
      initialQuery0 = @_options?.initialQuery ? {}
      initialQuery = (if typeof initialQuery0 is 'function'
        initialQuery0(query,type)
      else
        initialQuery0
      )

      r = queryComponents
        .map (qc)->
          output = qc.create(query,type, attributes)
          normalizeOutput output

        .reduce reducer, initialQuery

      call(postprocess) r
