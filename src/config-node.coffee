
module.exports = class ConfigNode
  constructor: (options)->
    @_options = options ? {}
    if not (this instanceof ConfigNode)
      throw new Error("You forgot to use 'new', doh.")

  # used to traverse the tree of config nodes.
  #
  # This method is supposed to return a dictionary of key-value pairs containing
  # the direct children of this node. 
  #
  # By default, this will look at the @_options property. If 
  # it is a non-null object (arrays *are* objects!), it will
  # simply return this object.
  #
  _expand: (settings, path) ->
    @_options if @_options? and typeof @_options is "object"
  
  # Usually, a node only depends on its own options. But there might be
  # situations where you want to access some node that lies outside your
  # own subtree. 
  #
  # This method will be called after construction of this node but *before*
  # init is called. It should return a dictionary of path expressions that point
  # to additional nodes that need to be initialized before this node is initialized.
  # 
  # Once all of those dependencies have been initialized, they will be passed
  # to this node's init method.
  #
  # Note: we compute the initialization order doing simple toposort. There is no
  # fixpoint iteration or anything fancy going on, so this only works for acyclic
  # dependency graphs. Cycles are detected while doing the sorting and will
  # raise an Error.
  dependencies: (settings, path) -> {}

  # This method gets called during initialization once all dependencies have
  # been initialized.  The dependencies are passed in as a dictionary. The
  # dictionary only includes those dependencies that have explicitly been
  # stated via the @dependencies-Method.  Every node does implicitly depend on
  # its options, which you can always access via the @_options member variable.
  init: (deps)->
    
