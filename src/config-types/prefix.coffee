Attribute = require './attribute'

module.exports= class Simple extends Attribute

  filter: (paramString)->
    bool: 
      should: for prefix in paramString.split ','
        prefix: "#{@options.field}": prefix.trim()
