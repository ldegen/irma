
Promise = require "bluebird"
{ ConfigNode } = require "@l.degener/irma-config"
stringify = Promise.promisify require "csv-stringify"

module.exports = class CsvEncoder extends ConfigNode
  encode: (data)->
    stringify data, @_options
