
{match} = require "./ast-matcher.coffee"
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
} = require "../src/ast-helper.coffee"

unparse = require "./ast-unparse.coffee"
{bottomup,ruleBased, matchAll, matchSome} = require "./ast-rewrite.coffee"

star = (tf)->(ast)->
  transformedAst = ast
  tmp = unparse ast
  output = ""
  for i in [0...250]
    ast = transformedAst
    {value:transformedAst} = transformed = tf ast
    output = unparse transformedAst
    return transformed if output is tmp
    tmp = output

chain = (tfs...)->(value)->
  for tf in tfs
    r = tf value
    {value} = r if r?

  {value}


isRoot = (value, path)-> if path.length is 0 then value
isNotRoot = (value, path)-> if path.length > 0 then value

A=[VAR, 'A']
As=[VARS, 'As']
B=[VAR, 'B']
Bs=[VARS, 'Bs']
Q=[VAR, 'Q']
occurs = (allowedOccs...)->(t)->t if isTerm(t) and t[0] in allowedOccs
InlineSequence = (occ)->[ [occ, [SEQ, As]], matchAll('As',occurs(occ))]
InlinePosSequence = [ [MUST, [SEQ, As]], matchAll('As', occurs(MUST, MUST_NOT))]
isSeq = (varName)->(subst)->subst if subst[varName][0] is SEQ
isNotSeq = (varName)->(subst)->subst if subst[varName][0] isnt SEQ


Normalize = (DEFAULT, log) ->
  bottomup ruleBased report:log, rules:[
    # normalization:
    # Start by converting all boolean expressions to sequence expressions with
    # occurence annotations.
    # (A OR B OR ... Z)    --> [?A ?B ... ?Z]
    ["Eliminate OR",  [OR,[VARS,'operands']]  , ({operands})->[DEFAULT, [SEQ].concat operands.map (o)->[SHOULD,o]]]
    # (A AND B AND ... Z)  --> [+A +B ... +Z]
    ["Eliminate AND", [AND,[VARS,'operands']] , ({operands})->[DEFAULT, [SEQ].concat operands.map (o)->[MUST,o]]]
    # (NOT A)              --> [-A]
    ["Eliminate NOT", [NOT,[VAR,'o']]         , ({o})->[DEFAULT, [SEQ,[MUST_NOT,o]]]]

    # Normalization
    # wrap leaf nodes and sequence nodes with an artifical DEFAULT occurence.
    # Later, during simplification phase, we will let these ripple up the tree
    # until they meet
    #   - another occurence annotation
    #   - as sequence node
    #   - the root
    ["Default OCC", [TERM, A]                , [DEFAULT,[TERM, A]]]
    ["Default OCC", [SQUOT, A]               , [DEFAULT,[SQUOT, A]]]
    ["Default OCC", [DQUOT, A]               , [DEFAULT,[DQUOT, A]]]
    ["Default OCC", [SEQ, As],isNotRoot      , [DEFAULT,[SEQ, As]]]
    ["Add RootSeq", A,isRoot,isNotSeq("A")   , [SEQ,A]]
  ]

Simplify = (log)->
  bottomup ruleBased report:log, rules:[
    # simplification:
    # Singleton-Sequences can be inlined, if the occurence of the element
    # is known.
    # [-a] --> -a, [+a] --> +a,  [?a] --> +a
    ["Singleton SEQ", [SEQ,[MUST_NOT, A]],isNotRoot            ,  [MUST_NOT, A] ]
    ["Singleton SEQ", [SEQ,[MUST, A]],isNotRoot                ,  [MUST, A] ]
    ["Singleton SEQ", [SEQ,[MUST, [SEQ, As]]]                  ,  [SEQ, As]]
    ["Singleton SEQ", [SEQ,[SHOULD, [SEQ, As]]]                ,  [SEQ, As]]
    ["Singleton SEQ", [SEQ,[SHOULD, A]],isNotRoot              ,  [MUST, A] ]
    ["Singleton SEQ", [SEQ,[SHOULD, A]], isRoot                ,  [SEQ, [MUST, A]]]
    ["Singleton SEQ", [SEQ, [SEQ, As]]                         ,  [SEQ, As]]

    # simplification:
    # What happens if two occurence annotations meet?
    # Note that in this case we pretend the inner occurence is wrapped in an imagenary
    # singleton sequence an interpret it accordingly. Thus an inner SHOULD will become MUST.
    ["Eliminate OCC", [MUST, [SHOULD, A]]                      ,  [MUST, A]]
    ["Eliminate OCC", [MUST, [MUST, A]]                        ,  [MUST, A]]
    ["Eliminate OCC", [MUST, [MUST_NOT, A]]                    ,  [MUST_NOT, A]]
    ["Eliminate OCC", [MUST_NOT, [SHOULD, A]]                  ,  [MUST_NOT,A]]
    ["Eliminate OCC", [MUST_NOT, [MUST, A]]                    ,  [MUST_NOT, A]]
    ["Eliminate OCC", [MUST_NOT, [MUST_NOT, A]]                ,  [MUST, A]]
    ["Eliminate OCC", [SHOULD, [SHOULD, A]]                    ,  [SHOULD, A]]
    ["Eliminate OCC", [SHOULD, [MUST, A]]                      ,  [SHOULD, A]]
    # Note that we cannot simplify ?(-(.)) !!


    # simplification:
    # Allow Occurence annotations to "ripple up" the tree until
    # they meet a sequence or the root.
    # Since the only other inner notes are field-qualifications
    # this is rather simple:
    ["Ripple Up",  [QLF, Q, [MUST, A]]         , [MUST,[QLF, Q,A]]]
    ["Ripple Up",  [QLF, Q, [MUST_NOT, A]]     , [MUST_NOT,[QLF, Q,A]]]
    ["Ripple Up",  [QLF, Q, [SHOULD, A]]       , [SHOULD,[QLF, Q,A]]]


    # if a sequence is marked with an occurence X and all its children are marked with the
    # same occurence, this sequence can be inlined.
    # (... +(+a +b +c ...) ...) ---> (... +a +b +c ... ...)
    ["Inline SEQ (1)", [SEQ, As], matchSome("As",InlineSequence(MUST),"Bs"), [SEQ, Bs]]
    ["Inline SEQ (1)", [SEQ, As], matchSome("As",InlineSequence(SHOULD),"Bs"), [SEQ, Bs]]

    # positive sequences can also be inlined if all elements occur with MUST or MUST_NOT
    # (... +(+a -b -c) ...) which could also be inlined.
    ["Inline SEQ (2)", [SEQ, As], matchSome("As",InlinePosSequence,"Bs"), [SEQ, Bs]]

    # DeMorgan I: (?(-a) ?-(b) ...)  ---> -(+a +b ... )
    ["De Morgan (1)", [SEQ, As], matchAll("As",[[SHOULD, [MUST_NOT,A]], [MUST,A]], "Bs"), [MUST_NOT, [SEQ,Bs]]]
    # DeMorgan II: -(?a ?b ... ) ---> -a -b ...
    ["De Morgan (2)", [MUST_NOT, [SEQ, As]], matchAll("As", [[SHOULD, A], [MUST_NOT, A]], "Bs"), [MUST, [SEQ, Bs]]]
  ]





Rewrite = (DEFAULT, log)->chain Normalize(DEFAULT, log), star(Simplify log)
normalize = Normalize(SHOULD)
rewrite = Rewrite(SHOULD)
simplify = Simplify()

module.exports = {normalize, simplify, star, chain, Simplify, Normalize, rewrite,Rewrite }
