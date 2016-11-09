module.exports = (query,type,options)->

  (rsp)->
    result =
      total:rsp.hits.total
      offset: if options?.offset then parseInt options.offset else 0
      hits:rsp.hits.hits.map (hit)->

        dstHit =
          score: hit._score
          data:
            id:hit._id
            type:hit._type

        attrs = (options?.types?[hit._type]?.attributes ? [])
        dsb = options?.types?[type]?.domainSpecificBehaviour
        # apply attribute-specific augmentations
        for attr in attrs when attr.augmentHit?
          attr.augmentHit  hit,dstHit

        # apply domain-specific augmentations not related to any particular attribute
        dsb?.augmentHit(hit,dstHit)
        
        dstHit

    if rsp.aggregations
      result.facetCounts = {}
      attrs = options?.types?[type]?.attributes ? []
      for attr in attrs when attr.interpreteAggResult?
        aggBody = rsp.aggregations[attr.name]
        if aggBody?
          result.facetCounts[attr.name] = attr.interpreteAggResult aggBody, result.total
      if options?.sorter?.interpreteAggResult?
        aggBody = rsp.aggregations._offsets
        if aggBody?
          result["sections"] = options.sorter.interpreteAggResult aggBody, result.total


    result
