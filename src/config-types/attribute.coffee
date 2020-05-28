
extend = require "deep-extend"
ConfigNode = require "../config-node"
module.exports=class Attribute extends ConfigNode
  prefix = (input,len)->
    if(!input?)
      return null
    if typeof input != "string"
      return input
    input = input.trim()
    if input.length <=len
      input
    else
      m = input.match ///^.{1,#{len}}\b///
      if m then m[0].trim()+" …" else input

  constructor: (options)->
    super options
    # The `field` option defines what index field is backing this attribute.
    # If `field` contains dots (`.`), it will be interpreted
    # as a path of dot-separated attribute names and traversed recursively.
    @field = options.field
    @name = options.name ? options.field

    # The `source` option defines how the field value is extracted from
    # the document source when displaying search result entries.
    # By default, it will look at the `field` option and extract
    # the corresponding attribute from the document.
    @source ?= options.source ? (src)->
      @field.split('.').reduce ((prev,cur)->prev?[cur]), src
    if @_options.augmentHit?
      @augmentHit ?= (src,dst)->
        f = @_options.augmentHit
        input = @renderResult src
        augmentation = f.call this, input, src, dst
        if f.length < 3 # the callback did not explicitly deal with dst
          switch typeof augmentation
            when 'function' then augmentation(dst)
            when 'object' then extend dst, augmentation
            else throw new Error('duh?!')
  findHighlightedMatches: (hit)->
    candidateFields = [@field]
    if @highlightSubfields?
      for subfield in Object.keys @highlightSubfields()
        candidateFields.push @field+"."+subfield

    for candidateField in candidateFields
      candidate = hit.highlight?[candidateField]
      return candidate if candidate?

  renderResult: (hit)->
    @findHighlightedMatches(hit)?.join(" … ") ? prefix(@source(hit._source),@_options.teaserLength ? 150)
