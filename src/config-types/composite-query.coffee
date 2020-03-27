
ConfigNode = require "../config-node"

flatmap = (arr, f)->
  reducer = (out, elm, i, arr)->out.concat f(elm,i,arr)
  arr.reduce reducer, []

empty = (a)->
  switch
    when not a? then true
    when Array.isArray(a) then a.length is 0
    when typeof a is "object" then switch
      when Object.keys(a).length is 0 then true
      when Object.keys(a).length is 1 and a.match_all? then true
      else false
    when typeof a is "string" then a.trim().length is 0
    else false

collectClauses = (occurence, options, args)->
  components = options[occurence] ? []
  components = [components] unless Array.isArray components
  clauses = flatmap components, (cmp)->cmp.apply args...
  clauses.filter (c)-> c? and not empty(c)

occurences = ["should", "must", "must_not", "filter"]

module.exports = class CompositeQuery extends ConfigNode

  apply: (args...)->
    body = {}
    clauseCount = 0
    for key,value of @_options when key not in occurences
      body[key] = @_options[key]
    for occurence in occurences
      clauses = collectClauses occurence, @_options, args
      clauseCount += clauses.length
      if clauses.length is 1
        body[occurence] = clauses[0]
      else if clauses.length > 1
        body[occurence] = clauses

    if clauseCount is 0 then match_all:{}
    else bool: body



