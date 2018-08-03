Attribute = require './attribute'

module.exports= class Prefix extends Attribute

  filter: (paramString)->
    bool: 
      should: for prefix in paramString.split ','
        prefix: "#{@field}": prefix.trim()
