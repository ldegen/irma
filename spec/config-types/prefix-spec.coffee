describe "prefix facette", ->
  Prefix = require '../../src/config-types/prefix'
  f=undefined

  beforeEach ->
    f= new Prefix field:"path"

  it "can construct a filter expression", ->
    expect(f.filter("9/401, 9/402")).to.eql
      bool: should: [
        prefix: path: "9/401"
      ,
        prefix: path: "9/402"
      ]
