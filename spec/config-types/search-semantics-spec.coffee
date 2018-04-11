describe "The Search Semantic", ->
  SearchSemantics = require "../../src/config-types/search-semantics"
  ConfigNode = require "../../src/config-node"

  settings = undefined
  semantics = undefined
  beforeEach ->
    settings = 
      types:project:
        searchSemantics: new SearchSemantics
        attributes: [
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
    semantics = settings.types.project.searchSemantics

  xit "builds a query using the given parser, query semantics and the fields of all attributes that contribute to the full-text search", ->
    args = query:{q:"bienen"},type:'project'
    expect(semantics.apply args, settings).to.eql
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
    args = query:{q:""}, type:'project'
    expect(semantics.apply(args,settings)).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []

  it "ommits the query part if given a query string containing only whitespace", ->
    args = query:{q:"   "},type:'project'
    expect(semantics.apply(args, settings)).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []

  it "ommits the query part if given something falsy instead of a query string", ->
    args = query:{},type:'project'
    expect(semantics.apply(args, settings)).to.eql
      fields: ['q2','q3','q4']
      query: bool:
        filter: []


  it "supports filtering by attributes for attributes providing a filter expression", ->
    args = query:{q:"bienen", fachgebiet: "42,43"},type:'project'
    query=semantics.apply args, settings
    expect(query.query.bool.filter).to.eql [
      f1:"42,43"
    ]



