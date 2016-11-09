
extend = require "deep-extend"
module.exports=class Attribute
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
    if not (this instanceof Attribute)
      throw new Error("You forgot to use 'new', doh.")
    @field = options.field
    @name = options.name ? options.field
    @options = options
    @source ?= options.source ? (src)->
      @field.split('.').reduce ((prev,cur)->prev?[cur]), src
    if @options.augmentHit?
      @augmentHit ?= (src,dst)->
        f = @options.augmentHit
        augmentation = f.call this, (@renderResult src), src, dst
        if f.length < 3 # the callback did not explicitly deal with dst
          switch typeof augmentation
            when 'function' then augmentation(dst)
            when 'object' then extend dst, augmentation
            else throw new Error('duh?!')
      
  renderResult: (hit)->
    hit.highlight?[@field]?.join(" … ") ? prefix(@source(hit._source),@options.teaserLength ? 150)
