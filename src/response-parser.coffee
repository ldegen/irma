{fromJS,toJS} = require "immutable"
module.exports = (settings)->
  RequestParser = require "./request-parser"
  reqParser = RequestParser settings
  ({type, query={}})->
    ({hits, aggregations,suggest})->
      {offset=0}=query
      sorter = reqParser.sorter query:query, type:type
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


