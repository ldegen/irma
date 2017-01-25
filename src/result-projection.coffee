module.exports = (settings)->
  parse = require("./request-parser")(settings)
  {types} = settings
  (options)->
    {query:{offset},type}=options
    {domainSpecificBehaviour,attributes=[],suggestions=[]}=types[type]
    (rsp)->
      result =
        total:rsp.hits.total
        offset: if offset then parseInt offset else 0
        hits:rsp.hits.hits.map (hit)->

          dstHit =
            score: hit._score
            data:
              id:hit._id
              type:hit._type

          attrs = (types?[hit._type]?.attributes ? [])
          # apply attribute-specific augmentations
          for attr in attrs when attr.augmentHit?
            attr.augmentHit  hit,dstHit

          # apply domain-specific augmentations not related to any particular attribute
          domainSpecificBehaviour?.augmentHit(hit,dstHit)
          
          dstHit

      if rsp.aggregations
        result.facetCounts = {}
        for attr in attributes when attr.interpreteAggResult?
          aggBody = rsp.aggregations[attr.name]
          if aggBody?
            result.facetCounts[attr.name] = attr.interpreteAggResult aggBody, result.total
        sorter = parse.sorter options
        if sorter?.interpreteAggResult?
          aggBody = rsp.aggregations._offsets
          if aggBody?
            result["sections"] = sorter.interpreteAggResult aggBody, result.total

      if rsp.suggest?
        result.suggestions = {}
        for suggestion in suggestions
          input = rsp.suggest[suggestion.name]
          if input?
            result.suggestions[suggestion.name] = if suggestion.transform? then suggestion.transform input else input


      result
