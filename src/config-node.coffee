
module.exports = class ConfigNode
  constructor: (@_options={})->
    if not (this instanceof ConfigNode)
      throw new Error("You forgot to use 'new', doh.")
