{
  isTerm
  TERM
  MUST
  MUST_NOT
  SHOULD
  QLF
  SEQ
  OR
  AND
  NOT
  DQUOT
  SQUOT
  VARS
  VAR
} = require "../../src/ast-helper.coffee"


describe "The default AST Transformer", ->

  a = [TERM, 'a']
  b = [TERM, 'b']
  c = [TERM, 'c']
  d = [TERM, 'd']
  e = [TERM, 'e']

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
              query: 'a b c d'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ]
          must_not: [
            multi_match:
              query: 'x'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ]


  it "creates a query that requires each term to occur in at least one field", ->
    expect(transformer.transform([SEQ, a, b, c])).to.eql
      multi_match:
        query: 'a b c'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'

  it "understands OR Nodes", ->
    expect(transformer.transform([OR, [SEQ, a, b, c], [SEQ, d, e]])).to.eql
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
    # Note: due to the new AST simplification step,
    # both sequences will actually be joined. Therefor, the original test case
    # is a bit lame:
    expect(transformer.transform([AND, [SEQ,a,b,c], [SEQ, d, e]])).to.eql
      multi_match:
        query: 'a b c d e'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'

    # we can spice things up a bit by using or as default operator:
    transformer2 = new Transformer
      fields: ['field_a','field_b', 'field_c']
      defaultOperator: 'or'
    expect(transformer2.transform([AND, [SEQ,a,b,c], [SEQ, d, e]])).to.eql
      bool:
        must:[
          multi_match:
            query: 'a b c'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'or'
        ,
          multi_match:
            query: 'd e'
            type: 'cross_fields'
            fields: ['field_a','field_b', 'field_c']
            operator: 'or'
        ]

  it "understands AND nodes, even if the default operator is 'or'", ->
    expect(transformer.transform([SEQ,[MUST,a],[MUST,b]], null, qop:'or')).to.eql
      multi_match:
        query: 'a b'
        type: 'cross_fields'
        fields: ['field_a','field_b', 'field_c']
        operator: 'and'
        
  it "understands NOT nodes", ->
    expect(transformer.transform([NOT, [SEQ,a,b,c] ])).to.eql
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
      ast = ['SEQ', a,b,c, ['NOT',['SEQ',d,e]]]
      expect(transformer.transform(ast)).to.eql
        bool:
          must:[
            multi_match:
              query: 'a b c'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ]
          must_not: [
            multi_match:
              query: 'd e'
              type: 'cross_fields'
              fields: ['field_a','field_b', 'field_c']
              operator: 'and'
          ]
  describe "when setting 'or' as defaultOperator", ->
    beforeEach ->
      transformer = new Transformer
        fields: ['field_a','field_b', 'field_c']
        defaultOperator: 'or'
    it "combines sequences using disjunction", ->
      ast = ['SEQ', a,b,c, ['NOT',['SEQ', d, e]]]
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
    #FIXME: There is a caveat when using these customizations:
    #
    # Keep in mind that the AST will be noramlized *before*
    # the customatization kicks in. So for instance customizing boolean nodes
    # will have no effect because they are removed from the ast during normalization.
    #
    # Also, the current SEQ strategy will merge the results from
    # its direct children (which are guaranteed to be MUST,MUST_NOT or SHOULD nodes)
    # into a single boolean query.

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
          SQUOT: (operands, cx, orig)->
            overridden:
              orig: orig
              operands: operands
      ast = ['NOT', ['SQUOT', 'a double quoted phrase']]
      expect(transformer.transform ast).to.eql
        bool:
          must_not: [
            overridden:
              operands: ["a double quoted phrase"]
              orig:
                multi_match:
                  query: 'a double quoted phrase'
                  type: 'phrase'
                  fields: ['oink']
          ]


    it "allows to define arbitrary context-transformations for particular node types", ->
      # this is very useful for field qualifiers.

      transformer = new Transformer
        fields: ['oink']
        defaultOperator: 'or'
        transformContext:
          QLF: (operands)->
            fieldBoosts: [operands[0]]

      ast = [MUST_NOT, [QLF,"eek",[TERM, "overthink"]]]
      expect(transformer.transform ast).to.eql
        bool:
          must_not: [
            multi_match:
              query: "overthink"
              type: "cross_fields"
              fields: ["eek"]
              operator: "or"
          ]
