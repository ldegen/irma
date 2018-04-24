Attribute = require './attribute'

module.exports= class Simple extends Attribute

  aggregation: ->
    terms:
      field:@field
      size:@_options.buckets ? 0
  filter: (paramString)->
    parse = switch @_options?.type
      when "integer","date" then (s) ->parseInt s
      when "float" then (s) -> parseFloat s
      when "boolean" then (s) -> s?.toLowerCase().trim() == "true"
      else (s) -> s
    terms = {}
    terms[@field] = (paramString.split ',').map parse
    terms:terms
  interpreteAggResult: (aggBody)->
    buckets = {}
    for bucket in aggBody.buckets
      buckets[bucket.key] = bucket.doc_count
    buckets

