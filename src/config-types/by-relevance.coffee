module.exports = class ByRelevance extends require './by-field'

  constructor: ()->
    super {field:'_score'}, 'desc'
  direction: ()->
    super 'desc'

