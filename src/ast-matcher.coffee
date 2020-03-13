
merge = require "./shallow-merge"
{VAR,VARS, isTerm} = require "./ast-helper"

collapseVarargs = (subst, name)->
  unless name? and subst?
    return subst

  vars = subst[name]
  newSubst = merge subst,
    "#{name}": vars.map ([_,subvarName])->subst[subvarName]
  for [_,subvarName] in vars
    delete newSubst[subvarName]

  newSubst
expandVarargs = (totalLength, origArgs, subst)->

  reducer = ({args:prevArgs,subst:prevSubst, varargName:prevName}, arg)->
    if isTerm(arg) and arg[0] is "VARS"
      name=arg[1]
      values=subst[name]
      if values?
        newVars = values
      else
        N = (totalLength - origArgs.length + 1)
        newVars = ([VAR,"#{name}.#{i}"] for i in [0 ... N])

      args: [prevArgs..., newVars...]
      subst: merge prevSubst, "#{name}":newVars
      varargName:name
    else
      args: [prevArgs...,arg]
      subst: prevSubst
      varargName: prevName

  origArgs.reduce reducer, {args:[],subst:subst}

match = (pattern, ast, subst={})->
 
  # short-circuit if subst is null. This
  # happens if a check on a preceeding sibling node failed.
  unless subst?
    return null
  # short-circuit if pattern is not a term
  unless isTerm pattern
    return if pattern is ast then subst else null
  
  [pHead, pTail...] = pattern
  # check if pattern is a variable
  if pHead is VAR
    [varName] = pTail
    varValue = subst[varName]
    # is it bound?
    if varValue?
      # then match against its value
      match varValue, ast, subst
    else
      # return the extended substitution
      merge subst, {"#{varName}": ast}

  # if pattern is no variable, compare its signature with that of the ast
  else
    # short-circuit if ast is not a term
    unless isTerm ast
      return if pattern is ast then subst else null
    # expand any varargs
    aTail = ast.slice(1)
    {args:pTail, subst:childSubst, varargName} = expandVarargs aTail.length, pTail, subst
    if pHead isnt ast[0] or pTail.length isnt aTail.length
      # no match means: we are out.
      null
    else if ast.length is 1
      # if signatures match and there are no children, we are done.
      subst
    else
      # if signatures match, but there are children, check them recursively

      reducer = (prevSubst, pChild, i)->
        aChild = aTail[i]
        match pChild, aChild, prevSubst

      nextSubst = pTail.reduce reducer, childSubst
      
      # if a vararg was expanded, we need to re-substitute
      collapseVarargs nextSubst, varargName


find = (pattern, ast, prefix=[])->
  subst = match pattern, ast
  localMatches = if subst? then [{path:prefix, subst}] else []

  if isTerm(ast) and ast.length > 1
    reducer = (matches, child, i)->
      childMatches = find pattern, child, [prefix...,i]
      matches.concat childMatches
    ast.slice(1).reduce reducer, localMatches
  else
    localMatches

  

module.exports = {match, find}
