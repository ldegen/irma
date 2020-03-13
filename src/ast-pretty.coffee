
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
} = require "./ast-helper"

escapeDQ = (s)->
  s
    .replace /\\/g, '\\\\'
    .replace /"/g, '\\"'

escapeSQ = (s)->
  s
    .replace /\\/g, '\\\\'
    .replace /'/g, '\\\''


builder =(indent="")->
  stack = []
  vertical = false
  output = ""
  hCount = 0

  pushV:(head)->
    if hCount > 0
      if vertical
        output += "\n#{indent}"
      else
        output += ", "
    output += "[#{head}"
    stack.push {indent, vertical}
    indent += "  "
    vertical = true
    output += "\n#{indent}"
    hCount = 0
    this

  pushH:(head)->
    if hCount > 0
      if vertical
        output += "\n#{indent}"
      else
        output += ", "
    output += "[#{head}"
    stack.push {indent, vertical}
    vertical = false
    hCount++
    this
  pop:()->
    output += "]"
    {vertical, indent } = stack.pop()
  atom:(s)->
    if hCount > 0
      output += ", "
    output += s
  dquot:(s)->
    if hCount > 0
      output += ", \""
    output +=s
      .replace /\\/g, '\\\\'
      .replace /"/g, '\\"'
    output += "\""
  squot:(s)->
    if hCount > 0
      output += ", '"
    output +=s
      .replace /\\/g, '\\\\'
      .replace /'/g, '\\\''
    output += "'"

  output: -> output

pretty = (t,  b=builder())->
  return unless isTerm(t)

  [head, args...] = t

  switch head
    when SEQ,AND,OR
      b.pushV head
      pretty arg, b for arg in args
      b.pop()
    when NOT, MUST, MUST_NOT, SHOULD
      b.pushH head
      pretty arg, b for arg in args
      b.pop()
    when QLF
      b.pushH head
      b.squot args[0]
      pretty args[1], b
      b.pop()
    when DQUOT,SQUOT,TERM
      b.pushH head
      b.squot args[0]
      b.pop()
    else
      throw new Error "ich hab was vergessen"

module.exports = (t, indent="")->
  b=builder(indent)
  pretty t,b
  b.output()
