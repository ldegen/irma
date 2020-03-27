
ConfigNode = require "../config-node"
{isArray} = require "util"
module.exports = class FilterQuery extends ConfigNode
  create: (query, type, attributes0)->

    attrs = attributes0 ? type?.attributes ? []
    filters = []

    for attr in attrs  when attr.filter?
      value = query[attr?.name]
      if(value?)
        filters.push attr.filter(value)

    query:bool:filter: filters
