module.exports = class CompositeSorter

  constructor: (sorters)->
    if not (this instanceof CompositeSorter)
      throw new Error("You forgot to use 'new', doh.")
    @sorters = sorters
    
  sort: ()->
