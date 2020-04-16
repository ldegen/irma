Attribute = require './attribute'
module.exports = class Fulltext extends Attribute
  constructor: (options)->
    super options
    @boost = options.boost
    @query = options.query ? true
    @includeSubfields = options.includeSubfields ? false


    if not @query
      @filter=(paramString)->
        match_phrase_prefix:"#{options.field}":
          query:paramString
          zero_terms_query: "all"


  highlight: ->
    @_options.highlight ? {}

