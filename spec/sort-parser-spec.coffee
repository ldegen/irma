describe "A parser for sort expressions", ->
  Parser = require "../src/sort-parser"
  CompositeSorter = require "../src/config-types/composite-sorter"
  ByRelevance = require "../src/config-types/by-relevance"
  mockSorter = (name, direction)->
    direction: (d)->
      mockSorter name, d
    trace: ()-> if direction? then [name,direction] else [name]

  sorters =
    relevance: mockSorter "relevance"
    name: mockSorter "name"
    rank: mockSorter "rank"
    year: mockSorter "year"
  trace = (sorter)->sorter.trace()
  parse = Parser sorters
  
  it "supports legacy syntax", ->
    expect(trace(parse("relevance,desc"))).to.eql ["relevance", "desc"]
  it "generalizes the old syntax to allow multiple criteria with different directions", ->
    r = parse("year,desc,name,rank,asc")
    expect(r).to.be.an.instanceOf CompositeSorter
    expect(r.sorters.map(trace)).to.eql [
      ["year", "desc"]
      ["name"]
      ["rank", "asc"]
    ]

  it "supports new, more compact syntax", ->
    expect(parse("~year,name,^rank").sorters.map(trace)).to.eql [
      ["year", "desc"]
      ["name"]
      ["rank", "asc"]
    ]

  it "creates a default sorter when passed an empty string", ->
    expect(parse("")).to.be.an.instanceOf ByRelevance

  it "silently ignores references to non-existing sorters", ->
    r = parse("yarr,desc,name,^honk,rank,asc")
    expect(r).to.be.an.instanceOf CompositeSorter
    expect(r.sorters.map(trace)).to.eql [
      ["name"]
      ["rank", "asc"]
    ]
