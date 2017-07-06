{fromJS,toJS} = require "immutable"
ConfigNode = require "../config-node"
module.exports = class DefaultView extends ConfigNode
  render: (searchResult)->
    types=@root().getAt("types")
    data: fromJS(searchResult).update "hits", (hits)->
      hits.map (hit)->
        type = hit.get "_type"
        {attributes=[], domainSpecificBehaviour} = (types?[type] ? {})
        dstHit =
          score: hit.get "_score"
          data:
            id:hit.get "_id"
            type: type

        # apply attribute-specific augmentations
        for attr in attributes when attr.augmentHit?
          attr.augmentHit  hit.toJS(),dstHit

        # apply domain-specific augmentations not related to any particular attribute
        domainSpecificBehaviour?.augmentHit(hit.toJS(),dstHit)
        fromJS dstHit
