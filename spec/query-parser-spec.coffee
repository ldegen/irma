describe "The Query Parser", ->
  parse = require("../src/query-parser").parse
  it "parses whitespace-separated ... things... ", ->
    expect(parse "foo, bar ba2=z").to.eql ['TERMS', 'foo,', 'bar', 'ba2=z']

  it "parses sequences with conjunctions and negations", ->
    expect(parse "a b AND c NOT d e f g").to.eql [
      'SEQ'
      [
        'TERMS',
        'a'
      ]
      [
        'AND',
        ['TERMS' ,'b'],
        ['TERMS', 'c']
      ]
      [
        'NOT',
        ['TERMS','d']
      ]
      ['TERMS','e','f','g']
    ]

  it "understands parentheses", ->
    expect(parse "x y ((a b) OR c) z").to.eql [
      'SEQ'
      ['TERMS', 'x','y']
      [
        'OR',
        [
          'TERMS',
          'a',
          'b'
        ],
        [
          'TERMS',
          'c'
        ]
      ]
      ['TERMS', 'z']
    ]

  it "falls back to trivial tokenizer when a parser exeption is caught", ->
    expect(parse "foo AND").to.eql ['TERMS', 'foo', 'AND']
    expect(parse "1) AND NOT bar").to.eql ['TERMS', '1', 'AND', 'NOT', 'bar']
