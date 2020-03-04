ConfigNode = require "../config-node"
module.exports=class Suggest extends ConfigNode
  init: ()->
    @field ?= @_options.field
    if typeof @field isnt "string"
      throw new Error("You *must* give me a field to work on.")
    @name ?= @_options.name ? @field


  build: (query) -> undefined #overwrite this with your own semantics
  transform: (data) -> data
