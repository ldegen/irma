MultiMatchQuery = require "../../src/config-types/multi-match-query.coffee"

describe "The Multi-Match Query", ->

  # This is more of an integration test. I created it to examine 
  # a few very specific regressions.
  # If you are interested in the details of the AST interpretation,
  # see the unit tests for ast-transformer
  
  query = undefined

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

    attributes = [
      field: "my_field"
      query:true
    ]
    query = (s, defaultOp='and')->mmq.create {q:s,qop:defaultOp}, "egal", attributes

  it "understands explicit AND", ->
    expect(query "holz AND termiten").to.eql
      fields: ['my_field']
      query:
        bool:
          should: [
            multi_match:
              query: "holz termiten"
              type: "cross_fields"
              fields: ['my_field^1']
              operator: 'and'
          ]
          minimum_should_match: 1
    
  it "understands explicit AND, even with defaultOp='or'", ->
    expect(query "holz AND termiten", 'or').to.eql
      fields: ['my_field']
      query:
        bool:
          should: [
            multi_match:
              query: "holz termiten"
              type: "cross_fields"
              fields: ['my_field^1']
              operator: 'and'
          ]
          minimum_should_match: 1
    
