module.exports = ({types})->
  ({type})->
    # this assumes all hits are from the same type
    # Otherwise a table gets... complicated.
    {attributes=[]}=(types?[type] ? {})
    headers = attributes.map ({name})->name
    ({hits})->
      mimeType: "text/csv"
      data: [headers].concat hits.map (hit)->
        attributes.map (attr)->
          attr.source hit._source

