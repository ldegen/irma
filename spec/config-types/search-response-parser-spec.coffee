describe "The Response Parser", ->
  {fromJS,toJS} = require "immutable"
  SearchResponseParser = require "../../src/config-types/search-response-parser" 
  settings =
    types:
      foo:
        suggestions:[
          name: "foo"
          transform: -> 42
        ]
        sort:
          by_fnord:
            interpreteAggResult: (body)->
              a:
                start:0
                length:1
                end:1
              b:
                start:1
                length:1
                end:2
              c:
                start:2
                length:1
                end:3
              c:
                start:3
                length:1
                end:4
        attributes: [
          name: "title"
          interpreteAggResult: (body)->
            A:1
            B:1
            C:1
            D:1
        ]
  docIds = ['a','b','c','d']

  query = 
    offset: 42
    sort:"by_fnord"
  respBody = 
    hits:
      total: 4711
      hits: docIds.map (id)->
        _type:'foo'
        _id:id
        _score:1
        _source: title: id.toUpperCase()
    aggregations:
      title: {}
      _offsets: {}
    suggest:
      foo: {}

  parser = new SearchResponseParser 
  parse = parser.transform {query:query, type:"foo"}, settings

  it "passes hits documents verbatim",->
    {hits} = parse respBody
    expect(hits).to.eql docIds.map (id)->
      _id:id 
      _type:'foo'
      _score: 1
      _source: title: id.toUpperCase()
  it "reports total and offset", ->
    {offset, total} = parse respBody
    expect(offset).to.eql 42
    expect(total).to.eql 4711
  it "reports facet counts for attributes supporting it", ->
    {facetCounts} = parse respBody
    expect(facetCounts).to.eql
      title:
        A:1
        B:1
        C:1
        D:1 
  it "reports secion offsets if the current sort configuration supports it", ->
    {sections} = parse respBody
    expect(sections).to.eql
      a:
        start:0
        length:1
        end:1
      b:
        start:1
        length:1
        end:2
      c:
        start:2
        length:1
        end:3
      c:
        start:3
        length:1
        end:4
  it "reports suggestions if configuration supports it",->
    {suggestions } = parse respBody
    expect(suggestions).to.eql
      foo:42
