sup = require "../response-parser-support"
{ ConfigNode } = require "@l.degener/irma-config"

mapObj = (obj,f)->
  r={}
  r[k] = f v for k,v of obj
  r

module.exports = class SearchResponseParser extends ConfigNode
  transform: (searchRequest, settings)->
    {
      facetCounts, sections, suggestions,
      hits, _request, _ast, offset, total
    } = mapObj sup, (f)->f(searchRequest, settings)

    (response)->

      hits: hits(response)
      _request: _request(response)
      _ast: _ast(response)
      offset: offset(response)
      total:total(response)
      facetCounts: facetCounts(response)
      sections: sections(response)
      suggestions: suggestions(response)

