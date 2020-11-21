
{ConfigBuilder} = require "@l.degener/irma-config"
defaults = require "./default-settings"
configTypes = require "./config-types"

showDeprecation=true

module.exports = (cfg=defaults, action)->
  if showDeprecation
    showDeprecation = false
    console.error """
    DEPRECATION WARNING:
    Your code seems to refer to the ConfigBuilder class through the IRMa public API.
    Note that the configuration subsystem was moved to a separate module.

    To setup an instance that behaves like the old one, do something like this:

    {ConfigBuilder} = require "@l.degener/irma-config"
    {defaults, configTypes} = require "irma"

    ConfigBuilder(defaults)
      .types configTypes
      #... your code

    """
  ConfigBuilder cfg, action
    .types configTypes

for key in Object.keys(ConfigBuilder)
  module.exports[key]=ConfigBuilder[key]
