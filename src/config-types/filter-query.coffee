
{ ConfigNode } = require "@l.degener/irma-config"
{isArray} = require "util"

createFilters = (query, type, attributes0)->
  attrs = attributes0 ? type?.attributes ? []
  filters = []

  for attr in attrs  when attr.filter?
    value = query[attr?.name]
    continue unless value?

    if not isArray value
      value = [value]

    for elm in value
      filters.push attr.filter(elm)

  filters

module.exports = class FilterQuery extends ConfigNode

  # legacy api
  create: (query, type, attributes0)->
    filters = createFilters query, type, attributes0
    if filters.length is 0 then {}
    else bool:filter: filters

  # new api
  apply: ({query, type:typeName}, settings, attributes)->
    type = settings?.types?[typeName]
    filters = createFilters query, type, attributes
    if filters.length is 0 then {match_all:{}}
    else filters

