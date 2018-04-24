
module.exports = (args...)->
  c = {}
  for arg in args
    c[key] = val for key,val of arg
  c
