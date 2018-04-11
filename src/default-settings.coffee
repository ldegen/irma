DefaultView = require "./config-types/default-view"
CsvEncoder = require "./config-types/csv-encoder"
SearchSemantic = require "./search-semantic"

module.exports =
  searchSemantic: new SearchSemantic
  bodyEncoders:
    "text/csv": new CsvEncoder {}
  defaultView:  new DefaultView
  views:
    default:  new DefaultView
  host: 'localhost'
  port: 9999
  elasticSearch:
    defaultType: 'project'
    index: 'app-test'
    host: 'localhost'
    port: 9200
    keepAlive: false
  pretty: true
  defaultLimit: 20
  hardLimit: 100
  proxy: {}
  static: {}
  types: {}
