DefaultView = require "./config-types/default-view"
CsvEncoder = require "./config-types/csv-encoder"
CsvView = require "./config-types/csv-view"
SearchSemantics = require "./config-types/search-semantics"
SearchRequestBuilder = require "./config-types/search-request-builder"
SearchResponseParser = require "./config-types/search-response-parser"
Pipeline = require "./config-types/pipeline"
Switch = require "./config-types/switch"
EsAdapter = require "./config-types/es-helper"
Io = require "./config-types/io"

module.exports =
  io: new Io
  elasticSearch: new EsAdapter
    defaultType: 'project'
    index: 'app-test'
    host: 'localhost'
    port: 9200
    keepAlive: false
  searchSemantics: new SearchSemantics
  searchRequestFilter: new SearchRequestBuilder
  
  searchResponseFilter:
    new Pipeline
      filters: [
        new SearchResponseParser
        new Switch
          expression: (searchRequest,settings)->searchRequest.query?.view
          cases:
            default: new DefaultView
            csv: new CsvView
      ]
  bodyEncoders:
    "text/csv": new CsvEncoder {}
  host: 'localhost'
  port: 9999
  pretty: true
  defaultLimit: 20
  hardLimit: 100
  proxy: {}
  static: {}
  types: {}
