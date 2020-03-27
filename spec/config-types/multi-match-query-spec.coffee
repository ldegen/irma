MultiMatchQuery = require "../../src/config-types/multi-match-query.coffee"
RootNode = require "../../src/root-node.coffee"
Io = require "../../src/config-types/io.coffee"
describe "The Multi-Match Query", ->

  # This is more of an integration test. I created it to examine
  # a few very specific regressions.
  # If you are interested in the details of the AST interpretation,
  # see the unit tests for ast-transformer

  query = undefined
  legacyQuery = undefined

  beforeEach ->
    mmq = new MultiMatchQuery
      #transformer: new Transforner
      #  defaultOp
      #  postProcess:(body, {fieldNames})->
      #    if Object.keys(body).length is 0
      #      fields:fieldNames
      #    else
      #      fields:fieldNames
      #      query:bool:
      #        should:[body]
      #        minimum_should_match: 1

    my_type =
      attributes:[
        field: "my_field"
        query: true
      ]
    settings = new RootNode
      types:
        my_type:my_type
    mmq.init io:new Io

    query = (s, defaultOp='and')->
      request =
        query: {q:s,qop:defaultOp}
        type: "my_type"
      mmq.apply(request, settings)

    legacyQuery = (s, defaultOp='and')->
      queryObj = {q:s,qop:defaultOp}
      mmq.create(queryObj, my_type)


  describe "new calling convention", ->
    it "understands empty queries", ->
      expect(query "").to.eql {match_all:{}}

    it "understands explicit AND", ->
      expect(query "holz AND termiten").to.eql
        multi_match:
          query: "holz termiten"
          type: "cross_fields"
          fields: ['my_field^1']
          operator: 'and'

    it "understands explicit AND, even with defaultOp='or'", ->
      expect(query "holz AND termiten", 'or').to.eql
        multi_match:
          query: "holz termiten"
          type: "cross_fields"
          fields: ['my_field^1']
          operator: 'and'

  describe "legacy calling convention", ->

    it "understands empty queries", ->
      expect(legacyQuery "").to.eql {}

    it "understands explicit AND", ->
      expect(legacyQuery "holz AND termiten").to.eql
        bool: must: [
          multi_match:
            query: "holz termiten"
            type: "cross_fields"
            fields: ['my_field^1']
            operator: 'and'
        ]
