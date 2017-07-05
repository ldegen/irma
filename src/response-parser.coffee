{fromJS,toJS} = require "immutable"
module.exports = (settings)->
  SortParser = require "./sort-parser"
  ({type, query={}})->
    ({hits, aggregations,suggest})->
      {offset=0}=query
      sortParser = SortParser(settings.types?[type]?.sort ? {})
      sorter = sortParser query.sort
      hits: hits.hits
      offset: offset
      total:hits.total
      facetCounts: (settings.types[type].attributes ? [])
        .reduce(
          (counts, attr)-> 
            if attr.interpreteAggResult?  and aggregations?[attr.name]?
              counts.set attr.name,attr.interpreteAggResult(aggregations[attr.name])
            else
              counts

          fromJS({})
        )
        .toJS()
      sections: if sorter.interpreteAggResult? and aggregations?._offsets?
        sorter.interpreteAggResult aggregations._offsets, hits.total
      suggestions: (settings.types[type].suggestions ? [])
        .reduce(
          (suggs, suggestor)->
            input = suggest[suggestor.name]
            if input?
              v = if suggestor.transform? then suggestor.transform input else input
              suggs.set suggestor.name, v
            else
              suggs
          fromJS({})
        )
        .toJS()


