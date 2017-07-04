describe "The Merger", ->
  Merger = require "../src/merger"
  merge = Merger()
  it "recursively merges objects", ->
    a =
      foo: 
        bar:42
      bang:9
    b =
      foo:
        oink:1
        bar:43
    expect(merge(a,b)).to.eql
      foo:
        bar:43
        oink:1
      bang:9

  it "replaces arrays", ->
    a = [1,2,3]
    b = [4,5]
    expect(merge(a,b)).to.equal b

  it "replaces fancy instances", ->
    class Oink
      constructor: (props)->
        this.key = val for key,val of props

    a = new Oink foo:42
    b = new Oink bar:24
    expect(merge(a,b)).to.equal b
  it "never modifies its inputs", ->
    a =
      foo: 
        bar:42
      bang:9
    b =
      foo:
        oink:1
        bar:43
    c =
      foo:
        rumpel:1
    merge([],a,b,c)
    expect(a.foo.bar).to.equal 42
    expect(a.foo).not.to.have.property "rumpel"
  it "can be customized", ->
    class MyObj
      constructor: (@data,@a,@b)->

    merge = Merger customMerge: (lhs,rhs, pass)->
      if rhs instanceof MyObj
        new MyObj merge(lhs.data, rhs.data), lhs, rhs
      else pass
    a =
      foo: new MyObj bar: new MyObj baz: 24, oink: 23
    b =
      foo: new MyObj bar: new MyObj oink: 25
    
    obj = merge a,b
    expect(obj.foo).to.be.an.instanceof MyObj
    expect(obj.foo.data.bar).to.be.an.instanceof MyObj
    expect(obj.foo.data.bar.data).to.eql 
      baz: 24
      oink: 25
    expect(obj.foo.a).to.equal a.foo
    expect(obj.foo.b).to.equal b.foo
    expect(obj.foo.data.bar.a).to.equal a.foo.data.bar
    expect(obj.foo.data.bar.b).to.equal b.foo.data.bar
