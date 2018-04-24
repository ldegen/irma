ConfigNode = require "../config-node"

call = require "../call"
module.exports = class Pipeline extends ConfigNode
  transform: (request, settings)->
    filters = @_options.filters ? []
    reducer = (pipeline, filter)->
      pipeline.then call(filter)(request, settings)

    (input)->
      filters.reduce reducer, Promise.resolve input




