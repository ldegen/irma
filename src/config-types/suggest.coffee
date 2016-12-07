module.exports=class Suggest
  constructor: (options)->
    if not (this instanceof Suggest)
      throw new Error("You forgot to use 'new', doh.")

    @options ?= options

    @field ?= options.field
    if typeof @field isnt "string"
      throw new Error("You *must* give me a field to work on.")
    @name ?= options.name ? @field


  build: (query) -> undefined #overwrite this with your own semantics
  transform: (data) -> data
