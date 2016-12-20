Promise = require "bluebird"
merge = require "deepmerge"
compose = (funs...)-> funs.reduceRight (a,b)->(x...)-> b a x...
defaults = require("../default-settings.json")
path = require "path"
bulk = require "bulk-require"
{isArray} = require "util"
LoadYaml = require "./load-yaml"
loadConfigTypes = (dirs)->
  dirs
    .map (dir)-> bulk dir, '*'
    .reduce ((a,b)->merge a,b), {}

resolveStaticPaths = ( obj)->
  throw new Error("häh?"+obj) if typeof obj isnt "object"
  return null unless obj?
  dir = obj.__dirname ? if obj.__filename? then path.dirname obj.__filename
  return obj unless dir?

  if obj.static?
    tmp = {}
    tmp[key] = path.resolve dir, value for key, value of (obj.static ? {})
    obj.static = tmp
  obj

resolve = ({file, required, content, configTypes={}})->
  if file? 
    if content?
      merge {__filename:file, __dirname:path.dirname file}, content
    else
      loadYaml = LoadYaml configTypes, (not required)
      content = loadYaml file
      if content?
        merge content, __filename:file, __dirname:path.dirname file
      else null
  else
    content

mergeConfigs = (a={},b={})->
  filesA = a.__files ? if a.__filename? then [a.__filename] else []
  filesB = b.__files ? if b.__filename? then [b.__filename] else []
  files = filesA.concat filesB
  c = merge a, b
  delete c.__filename
  delete c.__dirname
  c.__files = files if files.length > 0
  c
identity = (x)->Promise.resolve x
arrows =
  unit: (cfg)-> wrap cfg, identity
  typePath: (dirs0...)->(cfg)->
    dirs = dirs0.map (d)->path.resolve d
    unit if dirs.length > 0 then merge cfg, __types: loadConfigTypes( dirs), __typePath:dirs else cfg
  load: (file, required=true)->(cfg) -> 
    unit mergeConfigs cfg, resolveStaticPaths resolve file:path.resolve(file), required:required, configTypes: cfg.__types, content:null
  tryLoad: (file)->arrows.load file, false
  add: (obj, file) -> (cfg) -> unit mergeConfigs cfg, resolveStaticPaths resolve file:(if file then path.resolve file), content:obj
  then: (f)->if not f? then unit else ((cfg)->wrap cfg, f)
unit = arrows.unit

wrap = (cfg=defaults, action=identity)->
  bind= (f=unit)->
    m = f cfg
    wrap m.cfg, (env, finalCfg, argv0)->
      Promise.resolve action env, finalCfg, argv0
        .then (argv1)->m.action env, finalCfg, argv1
  run= (env,argv)->action env,cfg,argv
  instance = bind: bind, action: action, cfg:cfg, run:run
  for key,value of arrows when key isnt "unit"
    do (key,value)->instance[key] = (args...)->@bind value args...
  instance

# the built-in functions are also made available as static "methods"
module.exports= wrap
module.exports[key]=value for key,value of arrows

