describe "A Config Node", ->

  ConfigNode = require "../src/config-node"
  it "always lets you access the options object it was created from", ->
    opts = foo: 42
    ct = new ConfigNode opts
    expect(ct.options).to.equal opts



  it "can propagate context down into subtrees", ->
    a = new ConfigNode foo:42
    b = new ConfigNode bar:9
    c = new ConfigNode oink:a:a, b:b
    d = new ConfigNode nein:
        nein: ja: c
        doch: nicht: "test"

    d.initCx()
    expect(a.parent()).to.equal c.options.oink
    expect(a.root()).to.equal d
    expect(a.path()).to.eql ['nein','nein','ja','oink','a']
    expect(d.root().getAt a.path() ).to.equal a

