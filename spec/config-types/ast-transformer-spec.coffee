describe "The default AST Transformer", ->

  # this is the one used by the multi-match query by default.

  Transformer = require "../../src/config-types/ast-transformer"

  transformer = null

  beforeEach ->
    transformer = new Transformer
      fields: ['field_a','field_b', 'field_c']

  it "creates a query that requires each term to occur in at least one field", ->
    expect(transformer.transform(['TERMS', 'a' ,'b','c'])).to.eql
      multi_match:
        query: 'a b c'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'

  it "understands OR Nodes", ->
    expect(transformer.transform(['OR', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
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
    expect(transformer.transform(['AND', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
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
    expect(transformer.transform(['NOT', ['TERMS','a','b','c'] ])).to.eql
      bool:
        must_not:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
  it "interpretes SEQ nodes just like conjunctions", ->
    expect(transformer.transform(['SEQ', ['TERMS','a','b','c'], ['TERMS', 'd', 'e']])).to.eql
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
