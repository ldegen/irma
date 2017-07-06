ConfigNode = require "../config-node"
module.exports = class CsvView extends ConfigNode
  initCx: (root, path)->
    super root, path
    attributesPath = [path.slice(0,2)..., "attributes"]
    @attributes = @root().getAt attributesPath

    if not @attributes?
      throw new Error("This view can only be used within the context
                       of some given document type.")

  render: ({hits})=>
    
    headers = @attributes.map ({name})->name
    
    headers:
      "Content-Disposition": "attachment; filename=\"export.csv\""
    mimeType: "text/csv"
    data: [headers].concat hits.map (hit)=>
      @attributes.map (attr)->
        source = attr.source hit._source
        return null if not source?
        if attr.options.export
          attr.options.export source
        else
          source.toString()

