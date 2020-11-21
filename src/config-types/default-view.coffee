{ ConfigNode } = require "@l.degener/irma-config"
{augmentHit} = require "../response-parser-support"
merge = require "../shallow-merge"
module.exports = class DefaultView extends ConfigNode
  transform: (searchRequest, settings)->@render(searchRequest, settings)
  apply: (searchRequest, settings)->@render(searchRequest, settings)
  render: (searchRequest, settings)->(searchResult)->
    data: merge searchResult,
      hits: searchResult.hits.map augmentHit(searchRequest, settings)
