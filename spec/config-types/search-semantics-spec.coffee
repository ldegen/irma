describe "The Search Semantic", ->
  SearchSemantics = require "../../src/config-types/search-semantics"
  ConfigNode = require "../../src/config-node"

  settings = undefined
  semantics = undefined
  mockQuery = (f)->
    create: (query, type, attributes)->f query.q
  beforeEach ->
    settings =
      types:project:
        searchSemantics: new SearchSemantics
          queryComponents:[
            # some fulltext query
            mockQuery (q)->query:bool:should:[mockFulltext:q]
            # some other search query that returns a no-op node
            mockQuery (q)->{} #
            # and a third one that returns a filter
            mockQuery (q)->query:bool:filter:[mockFilter:'foo']
            # and yet another one. Let's see what happens
            mockQuery (q)->query:bool:filter:[mockFilter:'bar']
          ]
    semantics = settings.types.project.searchSemantics

  it "builds a query by merging the output of the given queryComponents", ->
    args = query:{q:"bienen"},type:'project'
    expect(semantics.apply(args,settings)).to.eql
      query: bool:
        should:[
          mockFulltext:"bienen"
        ]
        filter:[
          mockFilter:'foo'
        ,
          mockFilter: 'bar'
        ]

