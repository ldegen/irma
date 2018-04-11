Attribute = require "./attribute"
module.exports = class Geolocation extends Attribute


  filter: (parmString) ->
    [lat,lon,dist] = parmString.trim().split /\s*,\s*/
    field = @_options?.field ? 'geolocation'
    geo_distance:
      distance: dist
      "#{field}":
        lat:lat
        lon:lon
