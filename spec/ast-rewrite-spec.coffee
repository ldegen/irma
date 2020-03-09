{VARS,SEQ, OR, TERM, VAR,AND,QLF,SHOULD,MUST_NOT,MUST,NOT,isTerm} = require "../src/ast-helper.coffee"
{replace, topdown, bottomup, ruleBased, applySubst} = require "../src/ast-rewrite.coffee"
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

      xit "creates a rule-based rewrite strategy", ->

        rules = [
          # normalization:
          # (A OR B OR ... Z)    --> [?A ?B ... ?Z]
          [[OR,[VARS,'operands']]  , ({operands})->[SEQ].concat operands.map (o)->[SHOULD,o]]
          # (A AND B AND ... Z)  --> [+A +B ... +Z]
          [[AND,[VARS,'operands']] , ({operands})->[SEQ].concat operands.map (o)->[MUST,o]]
          # (NOT A)              --> [-A]
          [[NOT,[VAR,'o']]         , ({o})->[SEQ,[MUST_NOT,o]]]


          # simplification:
          # [-[-a]] --> [+a]
          [ [SEQ, [MUST_NOT, [SEQ, [MUST_NOT, [VAR, 'A']]]]]  ,   ({ A })->[SEQ, [MUST, A]]]
          # [-[+a]] --> [-a]
          [ [SEQ, [MUST_NOT, [SEQ, [MUST, [VAR, 'A']]]]]      ,   ({ A })->[SEQ, [MUST_NOT, A]]]
          # [?a]    --> [+a]
          [ [SEQ, [SHOULD, [VAR, 'A']]]                       ,   ({ A })->[SEQ, [MUST, A]]]
          # [+[-a]] --> [-a]
          [ [SEQ, [MUST, [SEQ, [MUST_NOT, [VAR, 'A']]]]]      ,   ({ A })->[SEQ, [MUST_NOT, A]]]
          # [+[+a]] --> [+a]
          [ [SEQ, [MUST, [SEQ, [MUST, [VAR, 'A']]]]]          ,   ({ A })->[SEQ, [MUST, A]]]
          # [?[+a]] --> [?a]
          [ [SEQ, [SHOULD, [SEQ, [MUST, [VAR, 'A']]]]]        ,   ({ A })->[SEQ, [SHOULD, A]]]



          # something like this is missing: how can I match a variable-arity term, where all children
          # match some pattern?
          # One possibility would be to allow "guarded" variables in conjunction with VARS
          #
          #   [ [MUST, [SEQ, [VARS,'Elms',[SEQ, [MUST, 'Elm']]]]] ,   ({Elms})-> Elms.map ({Elm})->[MUST, 'Elm'] ]
          #
          # I decided against this approach for now since the substitutional semantics of the guards are 
          # not quite clear.
          #
          # On the other hand: rules are just chains of unary functions that break early if one of them returns null or undefined.
          #
          #[ [MUST, [SEQ, [VARS, 'Elms']]], (({Elms})->EL


        ]
        rewrite = bottomup ruleBased rules
        rewritten = rewrite(
          [OR,
            [TERM, 'a']
            [NOT
              [TERM,'b']]
            [AND,
              [TERM,'c']
              [TERM,'d']]]
        )
        expect(rewritten.tree).to.eql(
          [SEQ,
            [SHOULD,[TERM,'a']]
            [SHOULD,[SEQ
              [MUST_NOT,[TERM,'b']]]]
            [SHOULD,[SEQ
              [MUST,[TERM,'c']]
              [MUST,[TERM,'d']]]]]
        )

      it "simplifies everything", ->
