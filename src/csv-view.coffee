module.exports = ({types})->
  ({type})->
    # this assumes all hits are from the same type
    # Otherwise a table gets... complicated.
    {attributes=[]}=(types?[type] ? {})
    headers = attributes.map ({name})->name
    ({hits})->
      headers:
        "Content-Disposition": "attachment; filename=\"export.csv\""
      mimeType: "text/csv"
      data: [headers].concat hits.map (hit)->
        attributes.map (attr)->
          source = attr.source hit._source
          return null if not source?
          if attr.options.export
            attr.options.export source
          else
            source.toString()

