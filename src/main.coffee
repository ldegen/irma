cli = require "./cli"
Server = require "./server"
configs = cli()

Server configs
  .start()
  .done (settings)-> console.error "server listening on port #{settings?.port}"
