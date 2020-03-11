
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
    {value} = tf value
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


Normalize = (DEFAULT) ->
  bottomup ruleBased [
    # normalization:
    # Start by converting all boolean expressions to sequence expressions with
    # occurence annotations.
    # (A OR B OR ... Z)    --> [?A ?B ... ?Z]
    [[OR,[VARS,'operands']]  , ({operands})->[DEFAULT, [SEQ].concat operands.map (o)->[SHOULD,o]]]
    # (A AND B AND ... Z)  --> [+A +B ... +Z]
    [[AND,[VARS,'operands']] , ({operands})->[DEFAULT, [SEQ].concat operands.map (o)->[MUST,o]]]
    # (NOT A)              --> [-A]
    [[NOT,[VAR,'o']]         , ({o})->[DEFAULT, [SEQ,[MUST_NOT,o]]]]

    # Normalization
    # wrap leaf nodes and sequence nodes with an artifical DEFAULT occurence.
    # Later, during simplification phase, we will let these ripple up the tree
    # until they meet
    #   - another occurence annotation
    #   - as sequence node
    #   - the root
    [[TERM, A]                , [DEFAULT,[TERM, A]]]
    [[SQUOT, A]               , [DEFAULT,[SQUOT, A]]]
    [[DQUOT, A]               , [DEFAULT,[DQUOT, A]]]
    [[SEQ, As],isNotRoot      , [DEFAULT,[SEQ, As]]]
    [A,isRoot,isNotSeq("A")   , [SEQ,A]]
  ]

simplify = bottomup ruleBased [
  # simplification:
  # Singleton-Sequences can be inlined, if the occurence of the element
  # is known.
  # [-a] --> -a, [+a] --> +a,  [?a] --> +a
  [ [SEQ,[MUST_NOT, A]],isNotRoot            ,  [MUST_NOT, A] ]
  [ [SEQ,[MUST, A]],isNotRoot                ,  [MUST, A] ]
  [ [SEQ,[MUST, [SEQ, As]]]                  ,  [SEQ, As]]
  [ [SEQ,[SHOULD, [SEQ, As]]]                ,  [SEQ, As]]
  [ [SEQ,[SHOULD, A]],isNotRoot              ,  [MUST, A] ]
  [ [SEQ,[SHOULD, A]], isRoot                ,  [SEQ, [MUST, A]]]
  [ [SEQ, [SEQ, As]]                         ,  [SEQ, As]]

  # simplification:
  # What happens if two occurence annotations meet?
  # Note that in this case we pretend the inner occurence is wrapped in an imagenary
  # singleton sequence an interpret it accordingly. Thus an inner SHOULD will become MUST.
  [ [MUST, [SHOULD, A]]                      ,  [MUST, A]]
  [ [MUST, [MUST, A]]                        ,  [MUST, A]]
  [ [MUST, [MUST_NOT, A]]                    ,  [MUST_NOT, A]]
  [ [MUST_NOT, [SHOULD, A]]                  ,  [MUST_NOT,A]]
  [ [MUST_NOT, [MUST, A]]                    ,  [MUST_NOT, A]]
  [ [MUST_NOT, [MUST_NOT, A]]                ,  [MUST, A]]
  [ [SHOULD, [SHOULD, A]]                    ,  [SHOULD, A]]
  [ [SHOULD, [MUST, A]]                      ,  [SHOULD, A]]
  # Note that we cannot simplify ?(-(.)) !!


  # simplification:
  # Allow Occurence annotations to "ripple up" the tree until
  # they meet a sequence or the root.
  # Since the only other inner notes are field-qualifications
  # this is rather simple:
  [ [QLF, Q, [MUST, A]]         , [MUST,[QLF, Q,A]]]
  [ [QLF, Q, [MUST_NOT, A]]     , [MUST_NOT,[QLF, Q,A]]]
  [ [QLF, Q, [SHOULD, A]]       , [SHOULD,[QLF, Q,A]]]


  # if a sequence is marked with an occurence X and all its children are marked with the
  # same occurence, this sequence can be inlined.
  # (... +(+a +b +c ...) ...) ---> (... +a +b +c ... ...)
  [ [SEQ, As], matchSome("As",InlineSequence(MUST),"Bs"), [SEQ, Bs]]
  [ [SEQ, As], matchSome("As",InlineSequence(SHOULD),"Bs"), [SEQ, Bs]]

  # positive sequences can also be inlined if all elements occur with MUST or MUST_NOT
  # (... +(+a -b -c) ...) which could also be inlined.
  [ [SEQ, As], matchSome("As",InlinePosSequence,"Bs"), [SEQ, Bs]]

  # DeMorgan I: (?(-a) ?-(b) ...)  ---> -(+a +b ... )
  [ [SEQ, As], matchAll("As",[[SHOULD, [MUST_NOT,A]], [MUST,A]], "Bs"), [MUST_NOT, [SEQ,Bs]]]
  # DeMorgan II: -(?a ?b ... ) ---> -a -b ...
  [ [MUST_NOT, [SEQ, As]], matchAll("As", [[SHOULD, A], [MUST_NOT, A]], "Bs"), [SEQ, Bs]]
]





Rewrite = (DEFAULT)->chain Normalize(DEFAULT), star(simplify)
normalize = Normalize(SHOULD)
rewrite = Rewrite(SHOULD)

module.exports = {normalize, simplify, star, chain, Normalize, rewrite,Rewrite }
