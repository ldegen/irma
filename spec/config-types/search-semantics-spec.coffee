describe "The Search Semantic", ->
  SearchSemantics = require "../../src/config-types/search-semantics"
  ConfigNode = require "../../src/config-node"
  Io = require "../../src/config-types/io.coffee"
  trace = undefined
  io = undefined


  settings = undefined
  semantics = undefined
  mockQuery = (f)->
    create: (query, type, attributes)->f query.q
  mockQueryNewStyle = (f)->
    apply: (req, settings, attributes)->f req.query.q

  beforeEach ->
    trace = []
    io =
      console:
        warn: (args...)->
          console.warn args...
          trace.push args.join "\n"

  it "builds a query by merging the output of the given queryComponents", ->
    settings =
      types:project:
        searchSemantics: new SearchSemantics
          queryComponents:[
            # some fulltext query
            mockQuery (q)->bool:should:[mockFulltext:q]
            # some other search query that returns a no-op node
            mockQuery (q)->{} #
            # and a third one that returns a filter
            mockQuery (q)->bool:filter:[mockFilter:'foo']
            # and yet another one.
            mockQuery (q)->bool:filter:[mockFilter:'bar']
          ]
    semantics = settings.types.project.searchSemantics
    semantics.init {io}
    args = query:{q:"bienen"},type:'project'
    expect(semantics.apply(args,settings)).to.eql
      bool:
        should:[
          mockFulltext:"bienen"
        ]
        filter:[
          mockFilter:'foo'
        ,
          mockFilter: 'bar'
        ]

  it "drops any extranous 'query' prefix from component outputs", ->
    settings =
      types:project:
        searchSemantics: new SearchSemantics
          queryComponents:[
            # some fulltext query
            mockQuery (q)->query:bool:should:[mockFulltext:q]
            # some other search query that returns a no-op node
          ]
    semantics = settings.types.project.searchSemantics
    semantics.init {io}
    args = query:{q:"bienen"},type:'project'
    expect(semantics.apply(args,settings)).to.eql
      bool:
        should:[
          mockFulltext:"bienen"
        ]
    expect(trace.length).to.equal 1
    expect(trace[0]).to.contain "WARNING"
    expect(trace[0]).to.contain "query"

  it "creates a match_all query if none of the components contributes anything", ->

    settings =
      types:project:
        searchSemantics: new SearchSemantics
          queryComponents:[
            mockQuery (q)->{}
            mockQuery (q)->{}
            mockQuery (q)->{}
          ]
    semantics = settings.types.project.searchSemantics
    semantics.init {io}
    args = query:{q:"bienen"},type:'project'
    expect(semantics.apply(args,settings)).to.eql
      match_all:{}
