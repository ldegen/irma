
CompositeQuery = require "../../src/config-types/composite-query.coffee"

describe "The Composite Query", ->

  mockQuery = (names...)->apply: (req, settings, attributes)->
    if names.length is 1
      mock: names[0]
    else names.map (n)->mock:n

  emptyObjQ = apply: (req, settings, attributes)->{}
  emptyArrQ = apply: (req, settings, attributes)->[]
  matchAll = apply: (req, settings, attributes)->{match_all:{}}
  undefQ = apply: (req,settings,attributes)->undefined
  nullQ = apply: (req,settings,attributes)->null

  # these are just passed through to the component queries
  # so we do not care about the respective values here
  req = {}
  settings = {}
  attributes = undefined

  it "composes several query clauses into a boolean query", ->

    cq = new CompositeQuery
      must: mockQuery("foo")
      filter: mockQuery("bar")

    expect(cq.apply req, settings, attributes).to.eql
      bool:
        must: mock:"foo"
        filter: mock:"bar"

  it "allows multiple clauses per occurence", ->

    cq = new CompositeQuery
      should: [mockQuery("foo"),mockQuery("baz")]
      filter: [mockQuery("bar", "bang"),mockQuery("boink")]

    expect(cq.apply req, settings, attributes).to.eql
      bool:
        should: [{mock:"foo"},{mock:"baz"}]
        filter: [
          mock:"bar"
        ,
          mock:"bang"
        ,
          mock:"boink"
        ]

  it "skips empty clauses", ->

    cq = new CompositeQuery
      should: [emptyArrQ,mockQuery("baz"), emptyObjQ, mockQuery("bang"), nullQ, matchAll, undefQ]
      filter: matchAll
      must: [nullQ, emptyObjQ]

    expect(cq.apply req, settings, attributes).to.eql
      bool:
        should: [{mock:"baz"},{mock:"bang"}]

  it "copies all other options verbatim to the bool query body", ->
    cq = new CompositeQuery
      should: [mockQuery("phrase"), mockQuery("multi-match")]
      filter: mockQuery("filter1","filter2", "filter3")
      minimumShouldMatch: 1

    expect(cq.apply req, settings, attributes).to.eql
      bool:
        should: [{mock:"phrase"},{mock:"multi-match"}]
        filter: [{mock:"filter1"},{mock:"filter2"},{mock:"filter3"}]
        minimumShouldMatch: 1

  it "creates a match_all query if all clauses are empty", ->

    cq = new CompositeQuery
      filter: matchAll
      must: [nullQ, emptyObjQ]
      minimumShouldMatch:42
    expect(cq.apply req, settings, attributes).to.eql match_all:{}
