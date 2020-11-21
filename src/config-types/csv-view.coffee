{ ConfigNode } = require "@l.degener/irma-config"
module.exports = class CsvView extends ConfigNode

  render: ({types={}},{type}) -> ({hits})=>

    attributes = types?[type]?.attributes
    headers = attributes.map ({name})->name

    headers:
      "Content-Disposition": "attachment; filename=\"export.csv\""
    mimeType: "text/csv"
    data: [headers].concat hits.map (hit)=>
      attributes.map (attr)->
        source = attr.source hit._source
        return null if not source?
        if attr.options.export
          attr.options.export source
        else
          source.toString()

