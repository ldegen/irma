{ ConfigNode } = require '@l.degener/irma-config'

module.exports = class LegacyFetch extends ConfigNode
  install: (service, settings, es) ->

    es.fetch = (id, typeName)->
      es.get(null, settings)({id, typeName})
