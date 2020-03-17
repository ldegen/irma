ConfigNode = require "../src/config-node"
RootNode = require "../src/root-node"

describe "A Config Node", ->
  trace = []
  beforeEach -> trace = []

  class DependentNode extends ConfigNode
    dependencies: ()->@_options.dependencies ? []
    init: (dependencies)->
      @depValues = dependencies
      @name = @_options.name
      trace.push @name


  it "always lets you access the options it was create from", ->
    opts = foo: 42
    ct = new DependentNode opts
    expect(ct._options.foo).to.equal 42

  it "can have dependencies other than its options", ->
    foo = new DependentNode name:"foo"
    baz = new DependentNode name:"baz", dependencies: foo: ['/', 'foo']
    root = new RootNode
      foo: foo
      bar: baz: baz


    expect(root._options.bar.baz.depValues).to.eql foo: foo

  it "can assume that its dependencies have been initialized before itself", ->
    foo = new DependentNode name:"foo"
    bar =new DependentNode name:"bar", foo:foo
    baz = new DependentNode name:"baz", dependencies: bar: ['/', 'bar']
    root = new RootNode
      baz: baz
      bar: bar

    expect(trace).to.eql ["foo","bar","baz"]



  it "cannot depend on ancestor", ->
    foo = new DependentNode name:"foo", dependencies: barf: ['/']

    mistake = -> new RootNode foo: foo
    expect(mistake).to.throw()

  it "detects complexer dependency cycles", ->
    mistake = ->
      new RootNode
        foo: new DependentNode name:"foo", dependencies: baz: ['..','bar', 'baz']
        bar: baz: new DependentNode name:"baz", dependencies: foo: ['/','foo']
    expect(mistake).to.throw()

  describe "Path expressions", ->
    it "can be normalized", ->
      expect(RootNode.normalizePath [".","foo","bar",".","..","baz",".","."]).to.eql ["foo","baz"]
    it "... but not, if they refer to ancestors", ->
      mistake = ->
        RootNode.normalizePath [".","..", "bar"]
      expect(mistake).to.throw()


