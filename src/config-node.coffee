{ConfigNode} = require "@l.degener/irma-config"

showDeprecation=true
class IrmaConfigNode extends ConfigNode

  constructor: (args...)->
    if showDeprecation
      showDeprecation = false
      console.error """
      DEPRECATION WARNING:
      Your code seems to refer to the ConfigNode class through the IRMa public API.
      Note that the configuration subsystem was moved to a separate module.

      Please do something like

      {ConfigNode} = require "@l.degener/irma-config"

      instead.
      """
    super args...

module.exports = IrmaConfigNode
