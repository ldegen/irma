describe "Sorting by given Field", ->
  ByField = require '../../src/config-types/by-field'
  sorter = undefined

  beforeEach ->
    sorter = new ByField field:'blah'

  it "complains, if you try to instantiate it without the 'new' operator", ->
    expect -> ByField()
      .to.throw /new/

  it "can construct a sorting expression", ->
    sorter = sorter.direction('some direction')
    expect(sorter.sort()).to.eql
      'blah':'some direction'

  it "sorts in ascending direction by default", ->
    expect(sorter.sort()).to.eql
      'blah':'asc'
        
  it "supports sorting by more than one field", ->
    sorter = new ByField 
      fields: ['foo','bar']
      field: 'bang'

    expect(sorter.sort()).to.eql [
      {'bang':'asc'}
      {'foo':'asc'}
      {'bar':'asc'}
    ]
    expect(sorter.direction('some direction').sort()).to.eql [
      {'bang':'some direction'}
      {'foo':'some direction'}
      {'bar':'some direction'}
    ]

  it "creates an aggregation expression, if configured with a prefix field", ->
    sorter = new ByField
      field:'blah'
      prefixField: 'blub'
    expect(sorter.aggregation()).to.eql
      terms:
        field: 'blub'
        size: 0
  it "knows how to intereprete aggregations, if configured with a prefix field", ->
    sorter = new ByField
      field:'blah'
      prefixField: 'blub'
    interpretation = sorter.interpreteAggResult
      buckets: [
        key: 'a'
        doc_count: 1
      ,
        key: 'b'
        doc_count: 2
      ,
        key: 'c'
        doc_count: 3
      ,
        key: 'd'
        doc_count: 4
      ]
    expect(interpretation).to.eql
      a:
        start:0
        length:1
        end:1
      b:
        start:1
        length:2
        end:3
      c:
        start:3
        length:3
        end:6
      d:
        start:6
        length:4
        end:10
  it "takes sorting order in consideration when calculating the offsets", ->
    sorter = new ByField
      field:'blah'
      prefixField: 'blub'
    interpretation = sorter.direction("desc").interpreteAggResult
      buckets: [
        key: 'a'
        doc_count: 1
      ,
        key: 'b'
        doc_count: 2
      ,
        key: 'c'
        doc_count: 3
      ,
        key: 'd'
        doc_count: 4
      ]
    expect(interpretation).to.eql
      a:
        start:9
        length:1
        end:10
      b:
        start:7
        length:2
        end:9
      c:
        start:4
        length:3
        end:7
      d:
        start:0
        length:4
        end:4
    
