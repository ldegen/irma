
module.exports =(thing, methods = ['apply', 'transform'])->(args...)->
  if typeof thing is "function"
    return thing args...
  else if typeof thing is 'object'
    for method in methods when typeof thing[method] is 'function'
      return thing[method] args...
  throw new Error "don't know how to call this: #{thing?.constructor}"
