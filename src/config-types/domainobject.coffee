extend = require "deep-extend"
module.exports=class DomainObject
  constructor: (options)->
    @options = options ? {}
    if not (this instanceof DomainObject)
      throw new Error("You forgot to use 'new', doh.")

  augmentHit: (src,dst)->
    f = @options.augmentHit
    if f?
      augmentation = f.call this, src, dst
      if f.length < 2 # the callback did not explicitly deal with dst
        switch typeof augmentation
          when 'function' then augmentation(dst)
          when 'object' then extend dst, augmentation
          else throw new Error('duh?!')
