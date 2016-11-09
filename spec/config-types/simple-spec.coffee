describe "simple facette", ->
  Simple =require '../../src/config-types/simple'
  f=undefined
  beforeEach ->
    f = new Simple field:"blah"

  it "can construct a filter expression", ->
    expect(f.filter("nu,na")).to.eql
      terms:
        blah:['nu','na']
  it "provides an appropriate aggregation expression", ->
    expect(f.aggregation()).to.eql
      terms:
        field: 'blah'
        size: 0
  it "can limit the number of buckets used for aggregation", ->
    f= new Simple 
      field:"blah"
      buckets: 42
    expect(f.aggregation()).to.eql
      terms:
        field: 'blah'
        size: 42
  it "knows how to interprete aggregation results", ->
    interpretation = f.interpreteAggResult
      buckets:[
        key: 'EIN'
        doc_count: 40
      ,
        key: 'KOORD'
        doc_count: 5
      ]
    expect(interpretation).to.eql
      EIN:40
      KOORD:5
