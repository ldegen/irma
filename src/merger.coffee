console.error """
DEPRECATION WARNING:
  Somewhere in your code base, you require somehting like "irma/lib/merger.js".
  Please don't do that!
  For now, to make this warning go away you can do something like

    {Merger} = require "irma"

  or maybe

    {Merger} = require "@l.degener/irma-config"

  I haven't yet decided how to finally resolve this, but please note that
  this was originally not intended as public API of neither irma nor irma-config!!
"""

module.exports =require("@l.degener/irma-config").Merger
