{isArray} = require "util"
pass = {}
module.exports = ({customMerge}={})->
  shallowCopy = (thing)->
    switch 
      when isArray thing then [thing...]
      when thing instanceof Object
        o = {}
        for key,value of thing
          o[key]=value 
          #console.log "copying", key
        o
      else thing

  initialize = (last)->
    switch
      when isArray last then []
      when last instanceof Object then {}
      else last

  merge = (lhs, rhs, output0, inplace=false)->
    if customMerge
      decission = customMerge(lhs,rhs,pass)
      if decission is pass
        merge0 lhs, rhs, output0, inplace
      else
        decission
    else
      merge0 lhs, rhs, output0, inplace

  merge0 = (lhs, rhs, output0, inplace=false)->
    #console.log "merging", lhs, rhs, if inplace then "inplace" else "cloned"
    switch
      when not lhs? then rhs
      when rhs is null then rhs
      when not rhs? then lhs
      when not (rhs instanceof Object) then rhs
      when not (lhs instanceof Object) then rhs
      when lhs.constructor isnt Object or rhs.constructor isnt Object then rhs
      when isArray(rhs) or isArray(lhs) then rhs
      else
        output = if inplace or (output0 isnt lhs) then output0 else shallowCopy output0
        for key,value of rhs
          output[key] = merge output[key], value, output[key], inplace
        output




  reducer = ({data:lhs, inplace}, rhs)->
    output = merge lhs, rhs, lhs, inplace
    data:output
    inplace: inplace or (output isnt lhs) and (output isnt rhs)
    


  (args...)->
    {data} = args.reduce reducer, inplace:false
    data
