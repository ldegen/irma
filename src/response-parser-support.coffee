module.exports.facetCounts = ({type}, settings, attributes0)->({aggregations})->
  attributes = attributes0 ? settings.types[type]?.attributes ? []
  reducer = (counts, attr)->
    if attr.interpreteAggResult? and aggregations?[attr.name]?
      counts[attr.name] = attr.interpreteAggResult(aggregations[attr.name])
    counts

  attributes.reduce reducer, {}

module.exports.sections = ({type, query={}}, settings, SortParser0)->({aggregations, hits})->
  SortParser = SortParser0 ? settings.SortParser ? require "./sort-parser"
  parseSortSpec = SortParser settings.types?[type]?.sort ? {}
  sortSpec = query?.sort
  sorter = parseSortSpec(sortSpec)

  if sorter.interpreteAggResult? and aggregations?._offsets?
    sorter.interpreteAggResult aggregations._offsets, hits.total

module.exports.suggestions = (searchRequest, settings, suggestions0)->({suggest})->
  suggestions = suggestions0 ? settings.types[searchRequest.type]?.suggestions ? []
  reducer = (suggs, suggestor)->
    input = suggest[suggestor.name]
    if input?
      v = if suggestor.transform? then suggestor.transform input else input
      suggs[suggestor.name] = v
    suggs
  suggestions.reduce reducer, {}

module.exports.hits = ()->({hits})->hits.hits
module.exports._request = ()->({_request})->_request
module.exports._ast = () -> ({_ast}) -> _ast
module.exports.offset = ({query}) -> () -> query?.offset ? 0
module.exports.total = ()-> ({hits})->hits.total
module.exports.augmentHit = (searchRequest, settings, attributes0, domainSpecificBehaviour0)->(hit)->
  typeName = hit._type ? searchRequest.type ? settings.defaultType
  type = settings.types[typeName] ? {}
  attributes = attributes0 ? type.attributes ? []
  domainSpecificBehaviour = domainSpecificBehaviour0 ? type.domainSpecificBehaviour
  dstHit =
    score: hit._score
    data:
      id:hit._id
      type: typeName
  dstHit.explanation = hit._explanation if hit._explanation?
  dstHit.fields = hit.fields if hit.fields

  # apply attribute-specific augmentations
  for attr in attributes when attr.augmentHit?
    x=attr.augmentHit  hit,dstHit
    x

  # apply domain-specific augmentations not related to any particular attribute
  domainSpecificBehaviour?.augmentHit(hit,dstHit)
  dstHit
