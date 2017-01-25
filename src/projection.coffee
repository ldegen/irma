module.exports = (settings)->
  ({query, type})->
    view = settings.types[type].views?[query._view]
    console.log "view",view
    (rsp)->
      {map, reduce, empty, encode,compose} = (view.init settings) ? view
      encode compose
        hits: rsp.hits.hits
          .map map
          .reduce reduce, empty()


      

