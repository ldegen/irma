Attribute = require './attribute'

module.exports= class Prefix extends Attribute

  filter: (paramString)->
    occur = @_options.occur ? "should"
    bool:
      "#{occur}": for prefix in paramString.split ','
        prefix: "#{@field}": prefix.trim()
