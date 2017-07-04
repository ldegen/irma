{isArray} = require "util"
propagate = (root, path, node)->
  switch
    when node instanceof ConfigNode
      if node._root isnt root or node._path isnt path
        node.initCx(root, path)
      else
        propagate root, path, node.options
    when isArray node
      for value, key in node
        propagate root, [path..., key], value
    when node instanceof Object
      for key,value of node
        propagate root, [path...,key], value



module.exports = class ConfigNode
  constructor: (@options={})->
    if not (this instanceof ConfigNode)
      throw new Error("You forgot to use 'new', doh.")

  initCx: (root=this, path=[])->
    @_root=root
    @_path=path
    propagate root, path, this

  parent: ->
    [path..., _] = @_path
    @_root.getAt path
  root: -> @_root
  path: -> @_path

  getAt: (path)->
    path.reduce ((obj,key)->if obj instanceof ConfigNode then obj.options?[key] else obj?[key]), @options

