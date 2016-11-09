describe "The Search Semantic", ->
  SearchSemantic = require "../src/search-semantic"

  options =
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
  semantic = SearchSemantic options, parser, Query

  it "builds a query using the given parser, query semantics and the fields of all attributes that contribute to the full-text search", ->
    expect(semantic({q:"bienen"},'project',options)).to.eql
      bool:
        must:
          testQuery:
            ast: parsed: "bienen"
            opts: fields:
              q2:1
              q3:1.5
              q4:1
        filter: []

  it "ommits the query part if given an empty query string", ->
    expect(semantic({q:""},'project')).to.eql
      bool:
        filter: []

  it "ommits the query part if given a query string containing only whitespace", ->
    expect(semantic({q:"   "},'project')).to.eql
      bool:
        filter: []

  it "ommits the query part if given something falsy instead of a query string", ->
    expect(semantic({},'project')).to.eql
      bool:
        filter: []


  it "supports filtering by attributes for attributes providing a filter expression", ->
    query=semantic {q:"bienen", fachgebiet: "42,43"},'project', options
    expect(query.bool.filter).to.eql [
      f1:"42,43"
    ]



