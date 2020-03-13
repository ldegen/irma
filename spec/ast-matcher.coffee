
{VARS,SEQ, OR, TERM, VAR,AND, NOT, QLF} = require "../src/ast-helper.coffee"
{ match, find } = require "../src/ast-matcher.coffee"

# ast -> [value, ast]
describe "ast-matcher.match", ->

  it "can 'fill' holes in a pattern", ->

    # Our AST is a term. We encode it as a list.
    # Let's say our term is (seq (seq (or (term a) (term b))))
    # This would look like this:
    # ['SEQ',['SEQ', ['OR',['TERM','a'], ['TERM', 'b']]]]
    # we could use helper functinos to make writing this a little easier
    # ast = _seq(_seq(_or(_term('a'),_term('b'))))
    # or we could simply define constants for all the op-codes
    # (I think I prefer this, but it's a matter of taste)
    ast = [SEQ, [SEQ, [OR, [TERM, 'a'], [TERM, 'b']]]]

    # A "pattern" is just a term with one or more holes. (a.k.a. meta-variables)
    pattern = [SEQ, [SEQ, [VAR, 'A']]]
    
    # Here we have given the name 'A' to our hole.
    # Matching a given ast against a pattern will either fail or produce exactly one
    # match. The match will contain a total substitution for all holes.

    m = match pattern, ast
    expect(m).to.be.ok
    expect(m.A).to.eql [OR, [TERM, 'a'], [TERM, 'b']]

  it "checks that holes are 'filled' consistently", ->

    # The same variable can appear more than one time.
    # If it does, a matching AST must have matching subtrees in each of the holes.
    
    pattern = [SEQ, [VAR, 'A'], [TERM, 'b'], [VAR, 'A']]
     
    expect(match pattern, [SEQ, [TERM, 'x'], [TERM,'b'], [TERM, 'y']]).to.be.not.ok
    expect(match pattern, [SEQ, [TERM, 'x'], [TERM,'b'], [TERM, 'x']]).to.eql A:[TERM,'x']

  xit "supports an optional 'guard' for the variable", ->
    
    # The variable A can only be bound to qualified terms.

    pattern = [NOT, [VAR, 'A', [QLF,[VAR,'Q'],[VAR,'T']]]]

    # This is very similar to just writing [NOT, [QLF, [VAR, 'Q'], [VAR,'T']]].
    # So there is little to no point in using this directly with VAR nodes.
    # The real purpose of this feature is to support guards in VARS nodes.


    expect(match pattern, [NOT, [TERM, 'x']]).to.be.not.ok
    expect(match pattern, [NOT, [QLF, 42, [TERM,'x']]]).to.eql A:{Q:42, T:[TERM,'x']}

  describe "varargs", ->
    it "matches an arbitrary number of consecutive siblings", ->

      # there are times when you want to match an arbitrary number of sibling nodes.
      # Just use the pseudo-opc VARS instead of VAR. It can be combined with
      # VAR nodes, but there may be at most one VARS node in any list.
      pattern = [SEQ, [VAR, 'First'], [VAR, 'Second'], [VARS, 'Rest'],[VAR, 'Last']]
      ast = [SEQ
        [TERM, 1]
        [TERM, 2]
        [TERM, 3]
        [TERM, 4]
        [TERM, 5]
        [TERM, 6]
        [TERM, 7]
      ]
      expect(match pattern, ast).to.eql
        First: [TERM, 1]
        Second: [TERM, 2]
        Rest: [[TERM,3], [TERM, 4], [TERM, 5], [TERM, 6]]
        Last: [TERM, 7]
    it "matches an empty list of siblings", ->

      pattern = [SEQ, [VAR, 'First'], [VAR, 'Second'], [VARS, 'Rest'],[VAR, 'Last']]
      ast = [SEQ
        [TERM, 1]
        [TERM, 2]
        [TERM, 3]
      ]
      expect(match pattern, ast).to.eql
        First: [TERM, 1]
        Second: [TERM, 2]
        Rest: []
        Last: [TERM, 3]
    it "does not match negative-length lists", ->
      pattern = [SEQ, [VAR, 'First'], [VAR, 'Second'], [VARS, 'Rest'],[VAR, 'Last']]
      ast = [SEQ
        [TERM, 1]
        [TERM, 2]
      ]
      expect(match pattern, ast).to.be.not.ok

    it "does the usual consistency-thing", ->
      pattern = [SEQ,[OR,[VARS,'As']],[AND,[VARS,'As']]]

      expect(match pattern, [SEQ,[OR,[TERM,'a'],[TERM,'b']],[AND,[TERM,'a'],[TERM,'b']]]).to.be.ok
      expect(match pattern, [SEQ,[OR,[TERM,'a'],[TERM,'b']],[AND,[TERM,'a'],[TERM,'c']]]).to.not.be.ok

    it "checks check for consistent number of matched siblings", ->

      pattern = [SEQ,[OR,[VARS,'As']],[AND,[VARS,'As']]]

      expect(match pattern, [SEQ,[OR,[TERM,'a'],[TERM,'b']],[AND,[TERM,'a'],[TERM,'b']]]).to.be.ok
      expect(match pattern, [SEQ,[OR,[TERM,'a'],[TERM,'b']],[AND,[TERM,'a'],[TERM,'b'],[TERM,'c']]]).to.not.be.ok


describe "ast-matcher.find", ->

  it "finds all redexes matching a given pattern", ->
    pattern = [OR, [TERM, 'x'],[VAR,'A']]

    ast= [SEQ
      [OR
        [AND
          [TERM,1]
          [OR
            [TERM,'x']
            [OR
              [TERM, 'x']
              [TERM, 'y']]]]
        [OR
          [TERM,'x']
          [TERM,'z']]]]

    matches = find pattern,ast
    expect(matches.length).to.equal 3
    expect(matches).to.eql [
      path:[0,0,1]
      subst:A:[OR,[TERM,'x'],[TERM,'y']]
    ,
      path:[0,0,1,1]
      subst:A:[TERM,'y']
    ,
      path:[0,1]
      subst:A:[TERM,'z']
    ]
