describe "The Query Parser", ->
  parse = require("../src/query-parser").parse
  it "parses whitespace-separated ... things... ", ->
    expect(parse "foo, bar ba2=z").to.eql [
      'SEQ',
      ['TERM', 'foo,']
      ['TERM', 'bar']
      ['TERM', 'ba2=z']
    ]

  it "parses sequences with conjunctions and negations", ->
    expect(parse "a b AND c NOT d e f g").to.eql [
      'SEQ'
      [ 'TERM', 'a']
      [
        'AND',
        [ 'TERM', 'b']
        [ 'TERM', 'c']
      ]
      [
        'NOT',
        [ 'TERM', 'd']
      ]
      [ 'TERM', 'e']
      [ 'TERM', 'f']
      [ 'TERM', 'g']
    ]

  it "understands parentheses", ->
    expect(parse "x y ((a b) OR c) z").to.eql [
      'SEQ'
      ['TERM', 'x']
      ['TERM', 'y']
      [
        'OR',
        [
          'SEQ',
          [ 'TERM', 'a']
          [ 'TERM', 'b']
        ],
        [ 'TERM', 'c']
      ]
      ['TERM', 'z']
    ]

  it "understands double-quoted strings", ->
    expect(parse '"this AND that"').to.eql ['DQUOT', 'this AND that']

  it "understands escape sequences within DQSs", ->
    expect(parse '"this \\" \\\\that"').to.eql ['DQUOT', 'this " \\that']

  it "understands single-quoted strings", ->
    expect(parse "'this AND that'").to.eql ['SQUOT', 'this AND that']

  it "understands escape sequences within SQSs", ->
    expect(parse "'this \\' \\\\that'").to.eql ['SQUOT', 'this \' \\that']

  it "supports DQSs as operands to boolean operations", ->
    expect(parse '42 AND "this AND that"').to.eql [
      "AND"
      ['TERM', "42"]
      ['DQUOT', "this AND that"]
    ]

  it "supports DQSs within sequences, but keeps them separated from terms", ->
    expect(parse 'a b "this AND that" "more" c').to.eql [
      "SEQ"
      ['TERM', "a"]
      ['TERM', "b"]
      ['DQUOT', "this AND that"]
      ['DQUOT', "more"]
      ['TERM', "c"]
    ]



    

  it "falls back to trivial tokenizer when a parser exeption is caught", ->
    expect(parse "foo AND").to.eql [
      'SEQ'
      ['TERM','foo']
      ['TERM','AND']
    ]
    expect(parse "1) AND NOT bar").to.eql [
      'SEQ',
      ['TERM', '1']
      ['TERM', 'AND']
      ['TERM', 'NOT']
      ['TERM', 'bar']
    ]
