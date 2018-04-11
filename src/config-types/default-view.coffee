{fromJS,toJS} = require "immutable"
ConfigNode = require "../config-node"
module.exports = class DefaultView extends ConfigNode
  render: (settings)->(searchResult)=>
    types=settings?.types ? {}
    data: fromJS(searchResult).update "hits", (hits)->
      hits.map (hit)->
        type = hit.get "_type"
        {attributes=[], domainSpecificBehaviour} = (types?[type] ? {})
        dstHit =
          score: hit.get "_score"
          data:
            id:hit.get "_id"
            type: type
        dstHit.explanation = hit.get "_explanation" if hit.has "_explanation"
        dstHit.fields = hit.get "fields" if hit.has "fields"

        # apply attribute-specific augmentations
        for attr in attributes when attr.augmentHit?
          x=attr.augmentHit  hit.toJS(),dstHit
          x

        # apply domain-specific augmentations not related to any particular attribute
        domainSpecificBehaviour?.augmentHit(hit.toJS(),dstHit)
        fromJS dstHit
