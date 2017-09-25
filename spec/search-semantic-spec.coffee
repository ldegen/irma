describe "The Search Semantic", ->
  SearchSemantic = require "../src/search-semantic"

  settings =
    types:project:attributes: [
      name: 'fachgebiet'
      filter: (v)-> f1:v
    ,
      field: 'q2'
      query: true
    ,
      field: 'q3'
      boost: 1.5
      query: true
    ,
      field: 'q4'
      query: true
    ]

  parser = parse: (s)->parsed:s
  Query = (opts)->
    (ast)->
      testQuery:
        opts: opts
        ast: ast
  semantic = SearchSemantic settings, parser, Query

  it "builds a query using the given parser, query semantics and the fields of all attributes that contribute to the full-text search", ->
    expect(semantic query:{q:"bienen"},type:'project').to.eql
      ast: parsed: "bienen"
      fields: ['q2','q3','q4']
      query: bool:
        must:
          testQuery:
            ast: parsed: "bienen"
            opts: fields:
              q2:1
              q3:1.5
              q4:1
        filter: []

  it "ommits the query part if given an empty query string", ->
    expect(semantic(query:{q:""}, type:'project')).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []

  it "ommits the query part if given a query string containing only whitespace", ->
    expect(semantic(query:{q:"   "},type:'project')).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []

  it "ommits the query part if given something falsy instead of a query string", ->
    expect(semantic(query:{},type:'project')).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []


  it "supports filtering by attributes for attributes providing a filter expression", ->
    query=semantic query:{q:"bienen", fachgebiet: "42,43"},type:'project'
    expect(query.query.bool.filter).to.eql [
      f1:"42,43"
    ]



