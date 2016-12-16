module.exports = (configTypeDirs = [])->
  path = require "path"
  bulk = require "bulk-require"
  {isArray} = require "util"
  LoadYaml = require "./load-yaml"
  configTypeDirs = [configTypeDirs] unless isArray configTypeDirs
  configTypes = configTypeDirs
    .slice()
    .reverse()
    .map (dir)-> bulk dir, '*'
    .reduce ((a,b)->merge a,b), {}

  resolveStaticPaths = (file, obj)->
    dir = path.dirname file
    tmp = {}
    tmp[key] = path.resolve dir, value for key, value of (obj.static ? {})
    obj.static = tmp
    obj

  loadYaml = LoadYaml configTypes
  
  (configFile)-> resolveStaticPaths configFile, loadYaml configFile
