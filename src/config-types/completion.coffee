Suggest = require "./suggest"
module.exports = class Completion extends Suggest
  build: ({q})->
    if q?.trim().length
      text:q
      completion: field: @field
