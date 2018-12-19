ConfigNode = require "../src/config-node"
RootNode = require "../src/root-node"

class DependentNode extends ConfigNode
  dependencies: ()->@_options.dependencies
  init: (dependencies)->
    @depValues = dependencies
describe "A Config Node", ->

  it "always lets you access the options it was create from", ->
    opts = foo: 42
    ct = new ConfigNode opts
    expect(ct._options.foo).to.equal 42

  it "can have dependencies other than its options", ->
    foo = new ConfigNode "yes"
    baz = new DependentNode dependencies: foo: ['/', 'foo']
    root = new RootNode
      foo: foo
      bar: baz: baz


    expect(root._options.bar.baz.depValues).to.eql foo: foo

  it "cannot depend on ancestor", ->
    foo = new DependentNode dependencies: barf: ['/']

    mistake = -> new RootNode foo: foo
    expect(mistake).to.throw()

  it "detects complexer dependency cycles", ->
    mistake = ->
      new RootNode
        foo: new DependentNode dependencies: baz: ['..','bar', 'baz']
        bar: baz: new DependentNode dependencies: foo: ['/','foo']
    expect(mistake).to.throw()

  describe "Path expressions", ->
    it "can be normalized", ->
      expect(RootNode.normalizePath [".","foo","bar",".","..","baz",".","."]).to.eql ["foo","baz"]
    it "... but not, if they refer to ancestors", ->
      mistake = ->
        RootNode.normalizePath [".","..", "bar"]
      expect(mistake).to.throw()


