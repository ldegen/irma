Attribute = require "./attribute"
module.exports = class Geolocation extends Attribute

  constructor: (options) ->
    super options

  filter: (parmString) ->
    [lat,lon,dist] = parmString.trim().split /\s*,\s*/
    field = @options?.field ? 'geolocation'
    geo_distance:
      distance: dist
      "#{field}":
        lat:lat
        lon:lon
