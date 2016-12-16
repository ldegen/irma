Promise = require "promise"
ESHelper = require "./es-helper"
Service = require "./service"
Net= require("net")
http = require("http")
merge = require "deepmerge"
defaults = require("../default-settings")

probeUrl = (url)->
  new Promise (resolve,reject)->
    req=http.get url, (res)->
      resolve(res.statusCode < 400)
    req.on "error", reject

probeP = (port,down)->
  new Promise (resolve,reject)->
    c= Net.createConnection(port)
    c.on "error",(e)->
      resolve(down?true:false)
    c.on "connect",()->
      c.end()
      resolve(down?false:true)

Server = (configs)->
  settings = configs.reduce ((a,b)->merge a, b), defaults
  opsP = require "promise-ops"
  http = require "http"

  server = http.createServer Service(settings)



  start: (timeout)->
    if timeout
      server.timeout=timeout
    new Promise (resolve,reject)->
      server.listen settings.port, settings.host, ()->
        opsP.waitForP( ()->probeUrl("http://#{settings.host}:#{settings.port}/_irma")).then ()->
          resolve(settings)
        , (err)->
            reject(err)

  stop: ()->
    new Promise (resolve)->
      server.close resolve

module.exports = Server
