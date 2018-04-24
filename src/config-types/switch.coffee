ConfigNode = require "../config-node"
call = require "../call"
module.exports = class Switch extends ConfigNode
  transform: (request, settings)->
    v = call(@_options.expression,  ['apply'])(request, settings)
    choice = @_optoins.cases[v]
    call(choice)(request,settings)

