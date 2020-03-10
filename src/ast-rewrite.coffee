{isTerm, VAR, VARS} = require "./ast-helper.coffee"
sigmatch = require "sigmatch"
{match} = require "./ast-matcher.coffee"
merge = require "./shallow-merge.coffee"
replace = (ast, [i,tail...], replacement)->
  if not i?
    replacement ast
  else
    newAst = ast.slice()
    newAst[i+1] = replace ast[i+1], tail, replacement
    newAst

flatmapReducer = (f)->(prevArgs, arg,i)->
  processedArg = f arg, i
  if Array.isArray(processedArg) and not isTerm(processedArg)
    prevArgs.concat processedArg
  else
    prevArgs.concat [processedArg]


flatmapReducerWithCx = (f)->({cx:prevCx,value:prevArgs}, arg, i)->
  {cx:newCx, value:newArg} = f arg, i, prevCx
  
  if Array.isArray(newArg) and not isTerm(newArg)
    cx:newCx
    value:prevArgs.concat newArg
  else
    cx:newCx
    value:prevArgs.concat [newArg]

applySubst = (s, term0)->
  recurseArgs = (args)->args.reduce flatmapReducer(recurse), []
  recurse = (term)->
    unless isTerm term
      return term
    [head, args...] = term
    if head is VAR
      recurse s[args[0]]
    else if head is VARS
      recurseArgs s[args[0]]
    else
      newArgs = recurseArgs args
      [head, newArgs...]
  recurse term0
    

topdown = (rewrite)->
  recurseArgs = (args,cx, path)->
    reducer = flatmapReducerWithCx (v,i,cx)->recurse v, cx, [path...,i]
    args.reduce reducer, cx:cx, value:[]
  recurse = (t0,cx0={},path=[])->
    if not isTerm(t0)
      # rewrite strategy is only applied on propper terms
      {cx:cx0, value:t0}
    else
      # we are going top-down, so we first have to pass the parent node to the
      # rewrite strategy
      {value,cx={}} = rewrite t0, cx0, path

      # the value produced by the strategy may be anything, so we have to
      # check here:
      
      # anything non-array-ish is passed on unchanged. There is no need
      # for recursion because there are no children.
      if not Array.isArray(value)
        {cx,value}

      # we may get an array that is not a propper term.
      # this can happen when e.g. a single argument is expanded to a list of arguments
      # In this case we will process the terms like an argument list, but we will not
      # construct a term from it.
      else if not isTerm(value)
        recurseArgs value, cx, path
      # a regular term with a head and zero or more arguments.
      # process the arguments recursively
      else
        [head,oldArgs...] = value
        {value:newArgs,cx:newCx} = recurseArgs oldArgs, cx, path
        value:[head,newArgs...]
        cx:newCx


bottomup = (rewrite)->
  recurseArgs = (args,cx, path)->
    reducer = flatmapReducerWithCx (v,i,cx)->recurse v, cx, [path...,i]
    args.reduce reducer, cx:cx, value:[]
  recurse = (t0, cx0={}, path=[])->
    # short-circuit for non-array stuff
    if not Array.isArray(t0)
      {cx:cx0, value:t0}
    # if it is an array, but not a propper term, we assume an array of terms
    else if not isTerm(t0)
      console.log "t0", t0
      throw new Error "FIXME: i think this should not happen?"
    else
      # first we hae to process the argument terms
      [head, oldArgs...] = t0
      {value:newArgs, cx: newCx} = recurseArgs oldArgs, cx0, path

      # now that we processed the arguments, construct a new
      # term and pass it to the rewrite strategy
      rewrite [head,newArgs...], newCx, path
      
compileRule = (rule)->
  ruleReducer = (prevf, f)->(v0, path)->
    v = prevf v0, path
    if v? then f v, path
  if typeof rule is "function"
    return [rule].reduce ruleReducer
  unless Array.isArray(rule)
    throw new Error "not a rule: "+rule

  if rule.length > 1
    [pattern0, guards..., template0] = rule
    template = if typeof template0 is "function" then template0 else (s)->applySubst s, template0
    
    pattern = switch
      when typeof pattern0 is "function" then pattern0
      when isTerm(pattern0) then (tree)->
        match pattern0, tree
      else
        throw new Error "cannot make a matcher from "+pattern0
    
    # composes the functions within a rule into one function
    [pattern, guards..., template].reduce ruleReducer
    
ruleBased = (opts)->
  if Array.isArray opts
    opts=rules:opts

  {rules:rules0, maxIterations=25} = opts
  


  rules = rules0.map compileRule


  (value,cx,path)->
    dirty = true
    i=0
    while dirty
      unless i<maxIterations
        throw new Error "no fixpoint in #{maxIterations} iterations"
      i++
      dirty = false
      for rule in rules
        newValue = rule value, path
        if newValue?
          value=newValue
          dirty=true
    {cx,value}


_matchAll = (InVar, Rule, OutVar)->
  rule = compileRule Rule
  (input, path)->
    subst = if InVar? then input else {}
    terms = if InVar? then input[InVar] else input
    return if not Array.isArray(terms)
    return if isTerm(terms)

    instances = (for orig in terms
      transformed = rule orig, path
      if transformed
        transformed
      else
        break
    )
    return null if instances.length isnt terms.length
    if OutVar?
      merge subst, "#{OutVar}": instances
    else
      instances

matchAll = sigmatch (m)->
  m "s,.,s?", _matchAll
  m ".,s?", (rule, OutVar)->_matchAll null, rule, OutVar

_matchSome = (InVar, Rule, OutVar)->
  rule = compileRule Rule
  (input, path)->
    subst = if InVar? then input else {}
    terms = if InVar? then input[InVar] else input
    return if not Array.isArray(terms)
    return if isTerm(terms)
    success = false

    instances = (for orig in terms
      transformed = rule orig, path
      if transformed
        success = true
        transformed
      else
        orig
    )
    return null unless success
    if OutVar?
      merge subst, "#{OutVar}": instances
    else
      instances

matchSome = sigmatch (m)->
  m "s,.,s?", _matchSome
  m ".,s?", (rule, OutVar)->_matchSome null, rule, OutVar
module.exports = {replace, topdown, bottomup, ruleBased, applySubst, matchAll, matchSome, compileRule}
