describe "The default AST Transformer", ->

  # this is the one used by the multi-match query by default.

  Transformer = require "../../src/config-types/ast-transformer"

  transformer = null

  beforeEach ->
    transformer = new Transformer
      fields: ['field_a','field_b', 'field_c']

  describe "when there are consecutive TERM nodes within a SEQ", ->
    it "it inlines the sequence to a single match/multi_match directive", ->
      expect(transformer.transform ['SEQ',['TERM','a'],['TERM','b'],['TERM','c']]).to.eql
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
    it "also works for mixed sequences", ->
      ast = [
        'SEQ'
        ['TERM','a']
        ['TERM','b']
        ['NOT',['TERM','x']]
        ['TERM','c']
        ['TERM','d']
      ]
      query = transformer.transform ast
      expect(query).to.eql
        bool:
          must: [
            multi_match:
              query: 'a b'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ,
            bool:
              must_not: [
                multi_match:
                  query: 'x'
                  type: 'cross_fields'
                  fields: ['field_a','field_b', 'field_c']
                  operator: 'and'
              ]
          ,
            multi_match:
              query: 'c d'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ]


  it "creates a query that requires each term to occur in at least one field", ->
    expect(transformer.transform(['TERM', 'a' ,'b','c'])).to.eql
      multi_match:
        query: 'a b c'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'

  it "understands OR Nodes", ->
    expect(transformer.transform(['OR', ['TERM','a','b','c'], ['TERM', 'd', 'e']])).to.eql
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
    expect(transformer.transform(['AND', ['TERM','a','b','c'], ['TERM', 'd', 'e']])).to.eql
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
    expect(transformer.transform(['NOT', ['TERM','a','b','c'] ])).to.eql
      bool:
        must_not:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'and'
        ]
  describe "by default", ->
    beforeEach ->
      transformer = new Transformer
        fields: ['field_a','field_b', 'field_c']
    it "interpretes SEQ nodes just like conjunctions", ->
      ast = ['SEQ', ['TERM','a','b','c'], ['NOT',['TERM', 'd', 'e']]]
      expect(transformer.transform(ast)).to.eql
        bool:
          must:[
            multi_match:
              query: 'a b c'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ,
            bool:
              must_not: [
                multi_match:
                  query: 'd e'
                  type: 'cross_fields'
                  fields: ['field_a','field_b', 'field_c']
                  operator: 'and'
              ]
          ]
  describe "when setting 'or' as defaultOperator", ->
    beforeEach ->
      transformer = new Transformer
        fields: ['field_a','field_b', 'field_c']
        defaultOperator: 'or'
    it "combines sequences using disjunction", ->
      ast = ['SEQ', ['TERM','a','b','c'], ['NOT',['TERM', 'd', 'e']]]
      expect(transformer.transform(ast)).to.eql
        bool:
          should:[
            multi_match:
              query: 'a b c'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'or'
          ,
            bool:
              must_not: [
                multi_match:
                  query: 'd e'
                  type: 'cross_fields'
                  fields: ['field_a','field_b', 'field_c']
                  operator: 'or'
              ]
          ]

  describe "explicit phrases", ->
    beforeEach ->
      transformer = new Transformer
        fields: ['field_a','field_b', 'field_c']
        defaultOperator: 'or'
    it "understands double-quoted phrases", ->
      ast = ['DQUOT', 'a double quoted phrase']
      expect(transformer.transform ast).to.eql
        multi_match:
          query: 'a double quoted phrase'
          type: 'phrase'
          fields: ['field_a','field_b', 'field_c']

    it "understands single-quoted phrases", ->
      ast = ['SQUOT', 'a double quoted phrase']
      expect(transformer.transform ast).to.eql
        multi_match:
          query: 'a double quoted phrase'
          type: 'phrase'
          fields: ['field_a','field_b', 'field_c']

  describe "customization", ->
    it "supports merging in static custom options for particular node types", ->
      transformer = new Transformer
        fields: ['oink']
        defaultOperator: 'or'
        customize:
          SQUOT:
            multi_match:
              analyzer: "extra_raw"

      ast = ['SQUOT', 'a double quoted phrase']
      expect(transformer.transform ast).to.eql
        multi_match:
          query: 'a double quoted phrase'
          type: 'phrase'
          fields: ['oink']
          analyzer: 'extra_raw'

    it "allows to dynamically rewrite the output for a particular node type", ->
      transformer = new Transformer
        fields: ['oink']
        defaultOperator: 'or'
        customize:
          NOT: (operands, recurse, orig)->
            overridden:
              orig: orig
              operands: operands
      ast = ['NOT', ['SQUOT', 'a double quoted phrase']]
      expect(transformer.transform ast).to.eql
        overridden:
          operands: [['SQUOT', 'a double quoted phrase']]
          orig:
            bool:
              must_not: [
                multi_match:
                  query: 'a double quoted phrase'
                  type: 'phrase'
                  fields: ['oink']
              ]


