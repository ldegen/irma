{ ConfigNode } = require "@l.degener/irma-config"
call = require "../call"
module.exports = class Switch extends ConfigNode
  transform: (request, settings)->
    v = call(@_options.expression,  ['apply'])(request, settings)
    choice = @_options.cases?[v ? 'default'] ? ()->(x)->x
    call(choice)(request,settings)

