describe "A Config Node", ->

  ConfigNode = require "../src/config-node"
  it "always lets you access the options it was create from", ->
    opts = foo: 42
    ct = new ConfigNode opts
    expect(ct._options.foo).to.equal 42





