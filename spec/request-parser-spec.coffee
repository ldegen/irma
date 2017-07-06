describe "The Request Parser", ->
  merge = require "deepmerge"
  # Actually the name is a bit misleading.
  # What it does is: take the parameters from the url and create components for a
  # ES query expression. Historically, most of this code was in the "ES-Helper", and it 
  # *is* very ES-specific. If you take a look at the `search` method within es-helper, you will
  # find that it does almost nothing. Everything happens here and in the response parser.
  # This is a bit odd. We will need to watch this.
  #
  # There are different functions for the different parts of the expression.
  RequestParser = require "../src/request-parser"
  myType=
    attributes:[
      name: "foo"
      highlight: -> "highlight me"
    ,
      name: "bar"
      highlight: -> "highlight me"
    ]
  settings =
    types:
      myType: myType
      defaultType: myType
    defaultType: "defaultType"
    searchSemantic: (input)->input: input
    SortParser:(parserSettings)->(sortExpression)->
      sort: ->
        sortExpression: sortExpression
        sortParserSettings: parserSettings
      aggregation: parserSettings.aggregation
    #defaultLimit: 42
    #hardLimit: 500

  RP = (overrides={})->RequestParser merge settings, overrides
  
  it "uses the SearchSemantic to create an ES-Query from the request's query string", ->
    rp = RP()
    expect(rp.query(query: "foobar")).to.eql input:query: "foobar"

  it "looks up the type in the settings, falling back to the default type if none is specified in the query", ->
    rp = RP()
    expect(rp.type(type: "myType")).to.equal "myType"
    expect(rp.type({})).to.equal "defaultType"

  it "handles offset and limit parameters, adhering to the configured default and hard limit", ->
    rp = RP defaultLimit: 42, hardLimit:500
    expect(rp.from(query:{})).to.eql 0
    expect(rp.from(query:offset:42)).to.eql 42
    expect(rp.size(query:{})).to.eql 42
    expect(rp.size(query:{limit:10})).to.eql 10
    expect(rp.size(query:{limit:100000})).to.eql 500

  # NOTE:
  # A lot of work is delegated to attributes and other config types.
  # This is no problem atm, but it scatters implicit ES-Dependencies
  # all over the place.
  # Should we ever want to use a different backend, we would have to
  # - create our own query language
  # - use this language in config types like attributes
  # - translate to the backend-specific language *here*

  it "delegates creation of highlighting directives to the attributes", ->
    rp=RP()
    expect(rp.highlight(type:'myType')).to.eql
      fields:
        foo: "highlight me"
        bar: "highlight me"

  it "adds suggest-directives if there are any configured for the requested type", ->
    rp=RP types:myType:suggestions:[
      name: "lorem"
      build: (q)-> suggestion:q
    ,
      name: "ipsum"
      build: (q)-> suggestion:q
    ]

    expect(rp.suggest query:"oink", type:"myType").to.eql
      lorem: suggestion: "oink"
      ipsum: suggestion: "oink"

  it "interpretes the `sort`-parameter, taking into  
      account the sort criteria configured for the type", ->
    rp = RP types:myType:sort: some:"sorterSettings"
    expect(rp.sort type: "myType", query:sort:"trallalla").to.eql
      sortParserSettings: some:"sorterSettings"
      sortExpression:"trallalla"

  it "adds aggs-directives for attributes requesting them", ->
    rp = RP types:myType:attributes: [
      name: "foo"
      aggregation: -> "foo_aggregation"
    ,
      name: "bar"
      aggregation: -> "bar_aggregation"
    ]
    expect(rp.aggs type: "myType").to.eql
      foo: "foo_aggregation"
      bar: "bar_aggregation"

  it "adds aggs-directives for sorters that require them", ->
    rp = RP types:myType:sort: 
      aggregation: -> "some aggregation"
    expect(rp.aggs type: "myType",query:sort:"blablabla").to.eql
      _offsets: "some aggregation"