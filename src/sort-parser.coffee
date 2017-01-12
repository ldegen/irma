module.exports = (sorters)->
  CompositeSorter = require "./config-types/composite-sorter"
  ByRelevance = require "../src/config-types/by-relevance"
  (s="")->
    return new ByRelevance if s.trim() is ""
    tokens = s.split ","
    reducer = (completedSorters, token)->
      [rest..., last] = completedSorters
      switch
        when token is "desc" then [rest..., last?.direction("desc")]
        when token is "asc" then [rest..., last?.direction("asc")]
        when token[0] is '~' then [completedSorters..., sorters[token.substr 1]?.direction("desc") ]
        when token[0] is '^' then [completedSorters..., sorters[token.substr 1]?.direction("asc") ]
        else [completedSorters..., sorters[token] ]
    usedSorters = tokens
      .reduce reducer, []
      .filter (x)->x?
    if usedSorters.length == 1 then usedSorters[0] else new CompositeSorter sorters:usedSorters
         

