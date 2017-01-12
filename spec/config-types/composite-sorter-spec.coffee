describe "The Composite Sorter", ->
  CompositeSorter = require "../../src/config-types/composite-sorter"
  mockSorter = (fields..., direction='asc')->
    sort: ()->
      exprs = fields.map (f)->"#{f}":direction
      if exprs.length is 1 then exprs[0] else exprs
    direction: (d)-> if d? then mockSorter fields..., d else direction
  a = mockSorter 'a', 'asc'
  b = mockSorter 'b','x','y', 'desc'
  c = mockSorter 'c',  'asc'

  it "combines a sequence of sorters", ->
    cs = new CompositeSorter sorters:[a,b,c]
    expect(cs.sort()).to.eql [
      {a:'asc'}
      {b:'desc'}
      {x:'desc'}
      {y:'desc'}
      {c:'asc'}
    ]

  describe ".direction('desc')", ->
    it "flips directions of compoent sorters", ->
      cs = new CompositeSorter sorters:[a,b,c]
      expect(cs.direction('desc').sort()).to.eql [
        {a:'desc'}
        {b:'asc'}
        {x:'asc'}
        {y:'asc'}
        {c:'desc'}
      ]
    it "is idempotent", ->
      cs = new CompositeSorter sorters:[a,b,c]
      expect(cs.direction('desc').direction('desc').sort()).to.eql [
        {a:'desc'}
        {b:'asc'}
        {x:'asc'}
        {y:'asc'}
        {c:'desc'}
      ]


  
