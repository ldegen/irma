module.exports = (args...)->
  {unit} = require "./config-builder"
  guessScript = (cfg)->
    if cfg.service?.script? then unit cfg
    else
      unit cfg
        .add service: script: process.argv[1]
  fillEnv = (cfg)->
    {__env={}, __usedEnvVars=[]}=cfg
    env = ({name:key, value:__env[key]} for key in __usedEnvVars when __env[key]?)
    if env.length > 0
      unit cfg
        .add service: env: env 
    else unit cfg
  (cfg)->
    unit cfg
      .bind guessScript
      .bind fillEnv
      .then ({Service},{service})->
        Service(service).install()
