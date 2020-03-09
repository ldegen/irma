{
  isTerm
  TERM
  MUST
  MUST_NOT
  SHOULD
  QLF
  SEQ
  OR
  AND
  NOT
  DQUOT
  SQUOT
} = require "../src/ast-helper.coffee"

priorities=
  TERM:0
  DQUOT:0
  SQUOT:0
  QLF:1
  MUST:2
  MUST_NOT:2
  SHOULD:2
  NOT:3
  AND:4
  SEQ:5
  OR:6

escapeDQ = (s)->
  s
    .replace /\\/g, '\\\\'
    .replace /"/g, '\\"'

escapeSQ = (s)->
  s
    .replace /\\/g, '\\\\'
    .replace /'/g, '\\\''

par =(op, term)->
  # poor man's function currying...
  if not term?
    (t)->par(op,t)
  else if isTerm term
    [head] = term
    parent = priorities[op]
    child = priorities[head]
    if not parent? or not child? or parent <= child
      "("+unparse(term)+")"
    else
      unparse term
  else
    term


unparse = (ast)->
  if not isTerm(ast)
    return ast
  
  [head, args...] = ast

  [first, second] = args
  switch head
    when TERM then first
    when MUST then "+"+par MUST, first
    when MUST_NOT then "-"+par MUST_NOT, first
    when SHOULD then "?"+par SHOULD, first
    when QLF then "#{first}:#{par QLF, second}"
    when SEQ then args.map(par SEQ).join " "
    when OR then args.map(par OR).join " OR "
    when AND then args.map(par AND).join " AND "
    when NOT then "NOT "+par(NOT, first)
    when DQUOT then "\"" + escapeDQ(first) + "\""
    when SQUOT then "'" + escapeSQ(first) + "'"
    else
      throw new Error "cannot unparse op #{head}"

module.exports = unparse
