DefaultView = require "./config-types/default-view"
CsvEncoder = require "./config-types/csv-encoder"
defaultView = new DefaultView {}

module.exports =
  bodyEncoders:
    "text/csv": new CsvEncoder {}
  defaultView: defaultView
  views:
    default: defaultView
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
