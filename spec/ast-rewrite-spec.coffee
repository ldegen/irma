{VARS,SEQ, OR, TERM, VAR,AND,QLF,SHOULD,MUST_NOT,MUST,NOT,isTerm} = require "../src/ast-helper.coffee"
{
  replace
  topdown
  bottomup
  ruleBased
  applySubst
  matchAll
  matchSome
  compileRule
} = require "../src/ast-rewrite.coffee"
{match} = require "../src/ast-matcher.coffee"
unparse = require "../src/ast-unparse.coffee"
describe "ast-rewrite", ->
  describe "replace", ->

    it "replaces a subtree within a term", ->

      ast =
        [SEQ
          [QLF
            "foo"
            [TERM, "42"]]
          [MUST
            [TERM, "unthink"]]]

      
      expect(replace ast, [1, 0], (T)->[NOT, T]).to.eql [
        SEQ
        [QLF
          "foo"
          [TERM, "42"]]
        [MUST
          [NOT, [TERM, "unthink"]]]
      ]

  describe "traversal strategies", ->
    describe "topdown", ->

      it "traverses top-down, left-right", ->

        ast =[OR,[TERM,'a'],[TERM,'b']]

        rewrite = topdown (t, {c=0}, path)->
          value: if isTerm(t) then [c+t[0],t.slice(1)...] else c+t
          cx:{c:c + 1}

        expect(rewrite(ast).value).to.eql ['0OR',['1TERM', 'a'],['2TERM','b']]
      
      it "can replace a single arg with a list of args", ->
        ast = [OR,[TERM, 'abc']]
        rewrite = topdown (t)->
          if t[0] is TERM and t[1].length > 1
            value:t[1].split("").map (s)->[TERM,s]
          else
            value:t
        actual = rewrite ast
        expect(actual.value).to.eql [
          OR
          [TERM, 'a']
          [TERM, 'b']
          [TERM, 'c']
        ]
        
    describe "bottomup", ->

      it "traverses bottom-up, left-right", ->

        ast =[OR,[TERM,'a'],[TERM,'b']]

        rewrite = bottomup (t, {c=0}, path)->

          value: if isTerm(t) then [QLF,c,t] else t
          cx:{c:c + 1}

        actual = rewrite ast
        expect(actual.value).to.eql [
          QLF,2
          [OR
            [QLF,0,[TERM, 'a']]
            [QLF,1,[TERM, 'b']]
          ]
        ]

      it "can replace a single arg with a list of args", ->
        ast = [OR,[TERM, 'abc']]
        rewrite = bottomup (t)->
          if t[0] is TERM and t[1].length > 1
            value:t[1].split("").map (s)->[TERM,s]
          else
            value:t
        actual = rewrite ast
        expect(actual.value).to.eql [
          OR
          [TERM, 'a']
          [TERM, 'b']
          [TERM, 'c']
        ]

    describe "applySubst", ->
      it "applies a variable substitution to a term", ->
        subst =
          A:[TERM,'a']
          B:[NOT,[VAR,'A']]

        template = [AND,[VAR,'A'],[VAR,'B']]

        expect(applySubst subst, template).to.eql [
          AND
          [TERM, 'a']
          [NOT, [TERM, 'a']]
        ]

      it "works correctly with VARS-pseudo-nodes", ->
        subst =
          As:[
            [TERM, 'a']
            [VAR, 'B']
          ]
          B: [SEQ,[VARS, 'Cs']]
          Cs: [
            [TERM, 'c1']
            [TERM, 'c2']
          ]
        template = [AND, [TERM,'first'],[VARS, 'As'],[TERM,'last']]
        
        expect(applySubst subst, template).to.eql [
          AND
          [TERM, 'first']
          [TERM, 'a']
          [SEQ
            [TERM, 'c1']
            [TERM, 'c2']]
          [TERM, 'last']]
        

    describe "rule-based rewrite", ->

      # The HOF ruleBased creates a rewrite strategy that is based on a set of rules.
      #
      # Each rule is basically a function that takes a proper term as input and produces
      # a single term or a list of terms as output. It does not have to be a total function.
      # If the result is undefined, it is assumed that the rule could not be applied to the
      # given term.
      #
      # A rule may also be specified as list of unary functions. The functions will be composed
      # with a simple combinator that breaks early if one of them yields an undefined result.
      #
      # If the rule is a list containing two or more functions, the first and the last function may
      # be specified as terms. If the first function is specified as a term, it will be interpreted
      # as a pattern and matched against the input term, producing a substitution on success.
      # If the last function is specified as a term, it will be interpreted as a template. Its
      # input should be a substitution which is used to instantiate the template.
      #
      # Thus, it should be possible to use classical TRS rules, but also to add more
      # logic, custom guard conditions, etc.

      it "supports classical TRS rules", ->
        rewrite = bottomup ruleBased [
          [ [NOT, [NOT, [VAR, 'A']]]                      ,   [VAR, 'A']]
          [ [AND, [NOT, [VAR, 'A']], [NOT, [VAR, 'B']]]   ,   [NOT, [OR, [VAR, 'A'], [VAR, 'B']]]]
          [ [OR, [NOT, [VAR, 'A']], [NOT, [VAR, 'B']]]    ,   [NOT, [AND, [VAR, 'A'], [VAR, 'B']]]]
        ]

        ast = [OR
          [NOT, [TERM, 'x']]
          [NOT
            [AND
              [NOT, [TERM, 'a']]
              [NOT, [TERM, 'b']]]]]
        actual = rewrite ast
        expect(actual.value).to.eql [OR
          [NOT, [TERM, 'x']]
          [OR
            [TERM, 'a']
            [TERM, 'b']]]

      it "can use functions for both lhs and rhs", ->
        rewrite = bottomup ruleBased [
          [
            (t)->
              if t[0] is OR
                Args: t.slice(1)
            ({Args})->
              [AND].concat Args.reverse()
          ]
        ]

        ast = [NOT,[OR,[TERM,1],[TERM,2],[TERM,3]]]
        actual = rewrite ast
        expect(actual.value).to.eql [NOT,[AND,[TERM,3],[TERM,2],[TERM,1]]]


      it "assumes the rule did not match when the lhs returns something falsy", ->
        
        lhs = (t)->
          if t[0] is TERM and t[1] isnt "touched" then {}
        rewrite = bottomup ruleBased [
          [lhs, [TERM, "touched"]]
        ]

        ast = [SEQ, [NOT, [TERM, 'x']],[OR, [TERM, 'y'], [TERM, 'z']]]
        actual = rewrite ast
        expect(actual.value).to.eql [SEQ, [NOT, [TERM, 'touched']],[OR, [TERM, 'touched'], [TERM, 'touched']]]
        
      it "assumes the rule did not match when the rhs returns something falsy", ->
        
        rhs = (t)->
          if t[0] is TERM and t[1] isnt "touched" then [TERM, "touched"]
        rewrite = bottomup ruleBased [
          [((t)->t), rhs]
        ]

        ast = [SEQ, [NOT, [TERM, 'x']],[OR, [TERM, 'y'], [TERM, 'z']]]
        actual = rewrite ast
        expect(actual.value).to.eql [SEQ, [NOT, [TERM, 'touched']],[OR, [TERM, 'touched'], [TERM, 'touched']]]


    describe "matchAll", ->

      it "applies a rule on a list of terms", ->
        terms = [
          [MUST, [TERM, "a" ]]
          [MUST, [TERM, "b" ]]
          [MUST, [TERM, "c" ]]
        ]
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchAllRule = matchAll rule

        expect(matchAllRule terms).to.eql [
          [MUST_NOT, [TERM, "a"]]
          [MUST_NOT, [TERM, "b"]]
          [MUST_NOT, [TERM, "c"]]
        ]

      it "fails if the rule cannot be applied to one or more term", ->
        terms = [
          [MUST, [TERM, "a" ]]
          [SHOULD, [TERM, "b" ]]
          [MUST, [TERM, "c" ]]
        ]
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchAllRule = matchAll rule

        expect(matchAllRule terms).to.not.be.ok

      it "can optionally lookup the input terms in a substitution", ->
        subst=
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchAllRule = matchAll "origTerms", rule

        expect(matchAllRule subst).to.eql [
          [MUST_NOT, [TERM, "a"]]
          [MUST_NOT, [TERM, "b"]]
          [MUST_NOT, [TERM, "c"]]
        ]

      it "can optionally merge the output terms into a substitution", ->
        subst=
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchAllRule = matchAll "origTerms", rule, "transformedTerms"

        expect(matchAllRule subst).to.eql
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
          transformedTerms:[
            [MUST_NOT, [TERM, "a"]]
            [MUST_NOT, [TERM, "b"]]
            [MUST_NOT, [TERM, "c"]]
          ]
          
    describe "matchSome", ->

      it "applies a rule on a list of terms", ->
        terms = [
          [MUST, [TERM, "a" ]]
          [MUST, [TERM, "b" ]]
          [MUST, [TERM, "c" ]]
        ]
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchSomeRule = matchSome rule

        expect(matchSomeRule terms).to.eql [
          [MUST_NOT, [TERM, "a"]]
          [MUST_NOT, [TERM, "b"]]
          [MUST_NOT, [TERM, "c"]]
        ]

      it "leaves terms unchanged for which the rule cannot be applied", ->
        terms = [
          [MUST, [TERM, "a" ]]
          [SHOULD, [TERM, "b" ]]
          [MUST, [TERM, "c" ]]
        ]
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchSomeRule = matchSome rule

        expect(matchSomeRule terms).to.eql [
          [MUST_NOT, [TERM, "a"]]
          [SHOULD, [TERM, "b"]]
          [MUST_NOT, [TERM, "c"]]
        ]

      it "fails if the rule cannot be applied to any term", ->
        terms = [
          [MUST_NOT, [TERM, "a" ]]
          [SHOULD, [TERM, "b" ]]
          [NOT, [TERM, "c" ]]
        ]
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchSomeRule = matchSome rule

        expect(matchSomeRule terms).to.not.be.ok

      it "can optionally lookup the input terms in a substitution", ->
        subst=
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchSomeRule = matchSome "origTerms", rule

        expect(matchSomeRule subst).to.eql [
          [MUST_NOT, [TERM, "a"]]
          [MUST_NOT, [TERM, "b"]]
          [MUST_NOT, [TERM, "c"]]
        ]

      it "can optionally merge the output terms into a substitution", ->
        subst=
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
        
        rule = [ [MUST, [VAR, 'A']], [MUST_NOT, [VAR, 'A']]]
        matchSomeRule = matchSome "origTerms", rule, "transformedTerms"

        expect(matchSomeRule subst).to.eql
          origTerms: [
            [MUST, [TERM, "a" ]]
            [MUST, [TERM, "b" ]]
            [MUST, [TERM, "c" ]]
          ]
          somethingElse: 42
          transformedTerms:[
            [MUST_NOT, [TERM, "a"]]
            [MUST_NOT, [TERM, "b"]]
            [MUST_NOT, [TERM, "c"]]
          ]

    describe "matchAll: Example DeMorgan's Law", ->
      A = [VAR, 'A']
      B = [VAR, 'B']
      As = [VARS, 'As']
      Bs = [VARS, 'Bs']
      # this is a real-life example of a two rules that use DeMorgan's Law
      # to reduce the total number of SEQ nodes
      it "transforms (?(-a) ?(-b) ?(-c)) to -(+a +b +c) [DeMorgan 1]", ->
        rule = compileRule [ [SEQ, As], matchAll("As",[[SHOULD, [MUST_NOT,A]], [MUST,A]], "Bs"), [MUST_NOT, [SEQ,Bs]]]
        input = [SEQ
          [SHOULD, [MUST_NOT, [TERM, 'a']]]
          [SHOULD, [MUST_NOT, [TERM, 'b']]]
          [SHOULD, [MUST_NOT, [TERM, 'c']]]]
        expected = [MUST_NOT, [SEQ
          [MUST, [TERM, 'a']]
          [MUST, [TERM, 'b']]
          [MUST, [TERM, 'c']]]]
        actual = rule input
        expect(actual).to.eql expected
      it "transforms -(a b c) to -a -b -c [DeMorgan 2]", ->
        rule = compileRule [ [MUST_NOT, [SEQ, As]], matchAll("As", [[SHOULD, A], [MUST_NOT, A]], "Bs"), [SEQ, Bs]]
        input = [MUST_NOT, [SEQ
          [SHOULD, [TERM, 'a']]
          [SHOULD, [TERM, 'b']]
          [SHOULD, [TERM, 'c']]]]
        expected = [SEQ
          [MUST_NOT, [TERM, 'a']]
          [MUST_NOT, [TERM, 'b']]
          [MUST_NOT, [TERM, 'c']]
        ]
        actual = rule input
        expect(actual).to.eql expected
        


    describe "matchAll/matchSome: a more complex example",->
      A = [VAR, 'A']
      B = [VAR, 'B']
      As = [VARS, 'As']
      Bs = [VARS, 'Bs']
      it "works", ->

        # This is a real-life example, a rule that is used to inline redundant
        # sequences.
        #
        # An inner sequence that apears within an outer sequence is redundant
        # if - all its elements have the same occurence annotation - the inner
        # sequence itself carries the same occurence annotation.  In this case,
        # the inner sequence can be inlined, i.e. all its elements can be
        # inserted directly into the outer sequence.
        #
        # For example: consider the term
        #
        # ( a b +(+c +d) +(+e +f +g) +(h +i) )
        #
        # Here the first and the second of the inner sequences are redundant.
        # The last one is not redundant because h does not carry the MUST
        # occurence annotation.  Our rule would reduce the above term to
        #
        # (a b +c +d +e +f +g +(h +i))
        #
        # We write the rule from the inside out.
        #
        # The inner-most rule simply accepts a term if it is of the form +A. It
        # does not yield a substitution, instead it returns the term unmodified
        # on success.
        #
        # The next rule accepts terms of the form +(A B C...) but only if each
        # of the A, B, C, ...  satisfies the first rule. This is the rule that
        # does the actual transformation: it basically inlines the SEQ node.
        # Note that it does not produce a substitution, but simply returns the
        # element terms on success -- WITHOUT the surrounding SEQ node.
        #
        # The outer-most rule accepts terms of the form (A B C...), i.e. any
        # sequence, but only if at least one of the elements A,B,C... can
        # successfully be transformed by the previous rule.  This rule takes
        # the transformed elements and rewrapps them into a SEQ node.

        innerMostRule = (t)->t if match [MUST,A], t
        middleRule = [ [MUST, [SEQ, As]], matchAll('As',innerMostRule)]
        outerRule = compileRule [ [SEQ, As], matchSome('As', middleRule, 'Bs'), [SEQ, Bs]]

        matchingTerm = [SEQ,
          [TERM, 'a']
          [TERM, 'b']
          [MUST,
            [SEQ
              [MUST, [TERM, 'c']]
              [MUST, [TERM, 'd']]]]
          [MUST,
            [SEQ
              [MUST, [TERM, 'e']]
              [MUST, [TERM, 'f']]
              [MUST, [TERM, 'g']]]]
          [MUST,
            [SEQ
              [TERM,'h']
              [MUST,[TERM, 'i']]]]]
        noMatchingTerm = [SEQ,
          [TERM, 'a']
          [TERM, 'b']
          [SHOULD,
            [SEQ
              [MUST, [TERM, 'c']]
              [MUST, [TERM, 'd']]]]
          [MUST,
            [SEQ
              [SHOULD, [TERM, 'e']]
              [MUST, [TERM, 'f']]
              [MUST, [TERM, 'g']]]]
          [MUST,
            [SEQ
              [TERM,'h']
              [MUST,[TERM, 'i']]]]]

        expect(outerRule noMatchingTerm).to.not.be.ok
        expected = [SEQ
          [TERM, 'a']
          [TERM, 'b']
          [MUST, [TERM, 'c']]
          [MUST, [TERM, 'd']]
          [MUST, [TERM, 'e']]
          [MUST, [TERM, 'f']]
          [MUST, [TERM, 'g']]
          [MUST,
            [SEQ
              [TERM,'h']
              [MUST,[TERM, 'i']]]]]
        
        actual = outerRule matchingTerm
        expect(actual).to.eql expected



