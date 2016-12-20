describe "The YAML reader/writer", ->
  LoadYaml = require "../src/load-yaml"
  jsYaml = require "js-yaml"
  ConfigType = require "../src"
  class Foo 
    constructor: (@options)->
      #duh.

  class Bar 
    constructor: (@options)->
      #duh.

  it "supports reading functions written in CoffeeScript", ->
    p=LoadYaml().parse """
    foo: !coffee |
      (x)->
        "(\#{x+x})"
    """
    expect(p.foo 42).to.eql "(84)"

  it "supports writing functions in some way or another", ->
    p=foo:(x)->"(#{x+x})"
    s = LoadYaml().unparse p
    p2 = LoadYaml().parse s
    expect(p2.foo 42).to.eql "(84)"

  it "supports reading custom types", ->
    p = LoadYaml(foo:Foo, bar:Bar).parse """
    obj: !foo
      stuff: 42
      text: |
        everything is cool
      children:
        - !bar
          very: easy
    """
    expect(p.obj).to.be.an.instanceOf Foo
    expect(p.obj.options.children[0]).to.be.an.instanceOf Bar

  it "supports writing custom types in some way or another", ->
    yaml = LoadYaml(foo:Foo, bar:Bar)
    p = 
      q: new Foo
        stuff: 42
        text: "everything is cool"
        children: [
          new Bar very:"easy"
        ]
    s = yaml.unparse p
    p2 = yaml.parse s
    expect(p2.q).to.be.an.instanceOf Foo
    expect(p2.q.options.children[0]).to.be.an.instanceOf Bar

