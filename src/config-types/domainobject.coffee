extend = require "deep-extend"
ConfigNode = require "../config-node"
module.exports=class DomainObject extends ConfigNode

  augmentHit: (src,dst)->
    f = @options.augmentHit
    if f?
      augmentation = f.call this, src, dst
      if f.length < 2 # the callback did not explicitly deal with dst
        switch typeof augmentation
          when 'function' then augmentation(dst)
          when 'object' then extend dst, augmentation
          else throw new Error('duh?!')
