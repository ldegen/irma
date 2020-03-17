ConfigNode = require "./config-node"
toposort = require "toposort"

normalizePath = (segments)->
  result = []
  for segment in segments
    switch segment
      when '/'
        result = []
      when '.'
        result = result
      when '..'
        throw new Error ("unexpected ..") if result.length < 1
        result.pop()
      else
        result.push segment
  result

expandItem = (root, {node, path})->
  if not node? or typeof node isnt "object"
    return []
  dict = if node instanceof ConfigNode then node._expand root, path else node
  for key, value of dict
    node: value
    path: [path..., key]

itemDependencies = (root, {node, path})->
  if not node? or typeof node isnt "object"
    {}
  dict = if node instanceof ConfigNode then node.dependencies root, path else {}
  deps = {}
  for key,depPath of dict
    deps[key] = normalizePath [path..., depPath...]
  deps

# This method is intended to be called *once* by the configuration subsystem
# after all configuration files, cli options, etc have been processed.  It
# will recursively traverse the configuration tree assuming this node as its
# root. While doing so, it will create a dependency graph which is then used
# to initialize all nodes in topological order.

initTree = (root)->
  todo = [{node: root, path:[]}]
  lookup = {}
  deps = []
  while todo.length > 0
    {node, path}= item = todo.pop()
    lookup[path]=item
    children = expandItem root, item
    dependencies = item.deps = itemDependencies root, item
    for child in children
      deps.push [path.toString(), child.path.toString()]
      todo.push child
    for alias, depPath of dependencies
      deps.push [path.toString(), depPath.toString()]
 
  sortedKeys = toposort(deps).reverse()

  for key in sortedKeys
    {node, path, deps} = lookup[key] ? {}
    #if not node?
    #  console.error "Warning: no node for path "+key
    if node? and node instanceof ConfigNode
      depvals = {}
      depvals[alias]=lookup[depPath]?.node for alias,depPath of deps
      node.init depvals

module.exports = class Root extends ConfigNode

  constructor: (options)->
    super options

    # make all options available as member variables
    this[key] = value for key, value of options

    initTree this
  

module.exports.normalizePath = normalizePath
    

