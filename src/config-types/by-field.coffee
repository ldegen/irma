ConfigNode = require "../config-node"
module.exports = class ByField extends ConfigNode


  constructor: (options, direction) ->
    @directionString = direction ? 'asc'
    super options

    if options.prefixField?
      @aggregation = ()->
        terms:
          field: options.prefixField
          size:0
      @interpreteAggResult = (body)->
        d = @directionString
        buckets = (body?.buckets ? [])
          .sort (a,b)->
            if 'asc' == d
              a.key.localeCompare b.key
            else
              b.key.localeCompare a.key
        sections = {}
        acc = 0
        for bucket in buckets
          sections[bucket.key]=
            start:acc
            length: bucket.doc_count
            end: acc+bucket.doc_count
          acc += bucket.doc_count
        sections



        

  direction: (string)-> 
    if string? then new ByField @options, string else @directionString
  sort: ()->
    direction = @directionString
    fields = @options.fields?.slice(0) ? []
    fields.unshift @options.field if @options.field
    if fields.length == 1
      "#{fields[0]}": direction
    else
      fields.map (field)->
        "#{field}": direction
