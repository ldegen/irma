describe "The Multi-Match Query", ->
  query = undefined
  Query = require "../src/multi-match-query"


  beforeEach ->
    query = Query
      fields: ['field_a','field_b', 'field_c']

  it "creates a query that requires each term to occur in at least one field", ->
    expect(query(['TERMS', 'a' ,'b','c'])).to.eql
      multi_match:
        query: 'a b c'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'

  it "understands OR Nodes", ->
    expect(query(['OR', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
      bool:
        should:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ,
          multi_match:
            query: 'd e'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
  it "understands AND nodes", ->
    expect(query(['AND', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
      bool:
        must:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ,
          multi_match:
            query: 'd e'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
  it "understands NOT nodes", ->
    expect(query(['NOT', ['TERMS','a','b','c'] ])).to.eql
      bool:
        must_not:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
  it "interpretes SEQ nodes just like conjunctions", ->
    expect(query(['SEQ', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
      bool:
        must:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ,
          multi_match:
            query: 'd e'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
