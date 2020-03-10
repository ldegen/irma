
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

A=[VAR, 'A']
As=[VARS, 'As']
B=[VAR, 'B']
Bs=[VARS, 'Bs']
Q=[VAR, 'Q']
DEFAULT = "DEFAULT"

normalize = bottomup ruleBased [
  # normalization:
  # Start by converting all boolean expressions to sequence expressions with
  # occurence annotations.
  # (A OR B OR ... Z)    --> [?A ?B ... ?Z]
  [[OR,[VARS,'operands']]  , ({operands})->[SEQ].concat operands.map (o)->[SHOULD,o]]
  # (A AND B AND ... Z)  --> [+A +B ... +Z]
  [[AND,[VARS,'operands']] , ({operands})->[SEQ].concat operands.map (o)->[MUST,o]]
  # (NOT A)              --> [-A]
  [[NOT,[VAR,'o']]         , ({o})->[SEQ,[MUST_NOT,o]]]

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
  [[SEQ, As]                , [DEFAULT,[SEQ, As]]]
]

simplify = bottomup ruleBased [
  # simplification:
  # Singleton-Sequences can be inlined, if the occurence of the element
  # is known.
  # [-a] --> -a, [+a] --> +a,  [?a] --> +a
  [ [SEQ,[MUST_NOT, A]]                      ,  [MUST_NOT, A] ]
  [ [SEQ,[MUST, A]]                          ,  [MUST, A] ]
  [ [SEQ,[SHOULD, A]]                        ,  [MUST, A] ]

  # simplification:
  # In many cases, occurences that appear directly below onother
  # occurence can be eliminated. However we cannot simply negate SHOULD
  # +(-a) --> -a, -(+a) --> -a
  [ [MUST, [MUST_NOT, A]]                    ,  [MUST_NOT, A]]
  [ [MUST_NOT, [MUST, A]]                    ,  [MUST_NOT, A]]
  # ?(?a) --> ?a, ?(+a) --> ?a, +(?a) --> ?a
  [ [SHOULD, [SHOULD, A]]                    ,  [SHOULD, A]]
  [ [SHOULD, [MUST, A]]                      ,  [SHOULD, A]]
  [ [MUST, [SHOULD, A]]                      ,  [SHOULD, A]]
  # +(+a) --> +a, -(-a) --> +a
  [ [MUST, [MUST, A]]                        ,  [MUST, A]]
  [ [MUST_NOT, [MUST_NOT, A]]                ,  [MUST, A]]

  # simplification:
  # If DEFAULT meets an actual occurence, it can be eliminated.
  [ [MUST, [DEFAULT, A]]        , [MUST,A]]
  [ [SHOULD, [DEFAULT, A]]      , [SHOULD,A]]
  [ [MUST_NOT, [DEFAULT, A]]    , [MUST_NOT,A]]
  [ [DEFAULT, [DEFAULT, A]]     , [DEFAULT,A]]

  # simplification:
  # Allow Occurence annotations to "ripple up" the tree until
  # they meet a sequence or the root.
  # Since the only other inner notes are field-qualifications
  # this is rather simple:
  [ [QLF, Q, [DEFAULT, A]]      , [DEFAULT,[QLF, Q,A]]]
  [ [QLF, Q, [MUST, A]]         , [MUST,[QLF, Q,A]]]
  [ [QLF, Q, [MUST_NOT, A]]     , [MUST_NOT,[QLF, Q,A]]]
  [ [QLF, Q, [SHOULD, A]]       , [SHOULD,[QLF, Q,A]]]


]


occurs = (occ)->(t)->t if match [occ,A], t
InlineSequence = (occ)->[ [occ, [SEQ, As]], matchAll('As',occurs(occ))]

applyDefault = bottomup ruleBased [
  # after the simplification phase is done,
  # DEFAULT occurences should only apear as direct children of SEQ nodes
  # or as the root node. We can also be sure that their children cannot be
  # occurence nodes.
  #
  # We substitute the DEFAULT nodes with SHOULD, since this is our
  # default semantics. We could also use MUST.
  [ [DEFAULT, A], [SHOULD, A]]

  # after that, we can run a final simplification rule:
  # if a sequence is marked with an occurence X and all its children are marked with the
  # same occurence, this sequence can be inlined.
  # (... +(+a +b +c ...) ...) ---> (... +a +b +c ... ...)
  [ [SEQ, As], matchSome("As",InlineSequence(MUST),"Bs"), [SEQ, Bs]],
  [ [SEQ, As], matchSome("As",InlineSequence(SHOULD),"Bs"), [SEQ, Bs]],
  [ [SEQ, As], matchSome("As",InlineSequence(DEFAULT),"Bs"), [SEQ, Bs]],

  # DeMorgan I: (?(-a) ?-(b) ...)  ---> -(+a +b ... )
  [ [SEQ, As], matchAll("As",[[SHOULD, [MUST_NOT,A]], [MUST,A]], "Bs"), [MUST_NOT, [SEQ,Bs]]]
  # DeMorgan II: -(?a ?b ... ) ---> -a -b ...
  [ [MUST_NOT, [SEQ, As]], matchAll("As", [[SHOULD, A], [MUST_NOT, A]], "Bs"), [SEQ, Bs]]
]
cleanup = bottomup ruleBased [
  # finally, we can remove most of the SHOULD occurences, since they are assumed to be the
  # default anyway.
  [ [SHOULD, [TERM, A]], [TERM, A ]]
  [ [SHOULD, [DQUOT, A]], [DQUOT, A ]]
  [ [SHOULD, [SQUOT, A]], [SQUOT, A ]]
  [ [SHOULD, [SEQ, As]], [SEQ, As ]]
  [ [SHOULD, [QLF, Q,A]], [QLF, Q,A ]]
  # We must not remove SHOULD if it preceeds MUST_NOT, at least not
  # if it apears in a sequence together with other terms.
  # We *can* however remove SHOULD if it appears at the very
  # root of the tree.
  [ [SHOULD, A], isRoot, A]
]


rewrite = chain normalize, star(simplify), star(applyDefault), cleanup

module.exports = {normalize, simplify, applyDefault, cleanup, rewrite}
