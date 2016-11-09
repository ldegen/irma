Attribute = require './attribute'
module.exports = class Fulltext extends Attribute
  constructor: (options)->
    super options
    @boost = options.boost


  highlight: ->
    @options.highlight ? {}
  query: true 
