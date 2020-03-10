
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
{bottomup,ruleBased} = require "./ast-rewrite.coffee"

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

# This works for somthing like (a ?(?b ?c) d) --> (a ?b ?c d).  I.e. there is a
# sequence within a sequence. The inner sequence is SHOULD and all its elements
# are SHOULD. Then the inner sequence could be inlined.  The same would work
# with MUST. (MUST_NOT is different!)
#
inlineSeq = (t)->
  return unless isTerm t

  [head, elms...] = t

  return unless head is SEQ

  precondition = (occ, elm)->
    m = match([occ, [SEQ, [VARS, 'Elms']]], elm)
    unless m?
      return false
    {Elms:subElms} = m
    subElms if subElms.every (subElm)->isTerm(subElm) and subElm[0] is occ

  dirty = false

  reducer = (prevElms, elm)->
    for occ in [SHOULD, MUST, DEFAULT]
      subElms = precondition occ, elm
      if subElms
        dirty = true
        return prevElms.concat subElms
    prevElms.concat [elm]

  transformedElms = elms.reduce reducer, []
  if dirty
    [head, transformedElms...]

isRoot = (value, path)-> if path.length is 0 then value

A=[VAR, 'A']
As=[VARS, 'As']
Q=[VAR, 'Q']
DEFAULT = "DEFAULT"

normalize = bottomup ruleBased [
  # normalization:
  # (A OR B OR ... Z)    --> [?A ?B ... ?Z]
  [[OR,[VARS,'operands']]  , ({operands})->[SEQ].concat operands.map (o)->[SHOULD,o]]
  # (A AND B AND ... Z)  --> [+A +B ... +Z]
  [[AND,[VARS,'operands']] , ({operands})->[SEQ].concat operands.map (o)->[MUST,o]]
  # (NOT A)              --> [-A]
  [[NOT,[VAR,'o']]         , ({o})->[SEQ,[MUST_NOT,o]]]

  # wrap sequences and leaf nodes in default occurence
  [[TERM, A]                , [DEFAULT,[TERM, A]]]
  [[SQUOT, A]               , [DEFAULT,[SQUOT, A]]]
  [[DQUOT, A]               , [DEFAULT,[DQUOT, A]]]
  [[SEQ, As]                , [DEFAULT,[SEQ, As]]]
]

simplify = bottomup ruleBased [
  # simplification:
  # [-a] --> -a, [+a] --> +a,  [?a] --> +a
  [ [SEQ,[MUST_NOT, A]]                      ,  [MUST_NOT, A] ]
  [ [SEQ,[MUST, A]]                          ,  [MUST, A] ]
  [ [SEQ,[SHOULD, A]]                        ,  [MUST, A] ]

  # +(-a) --> -a, -(+a) --> -a
  [ [MUST, [MUST_NOT, A]]                    ,  [MUST_NOT, A]]
  [ [MUST_NOT, [MUST, A]]                    ,  [MUST_NOT, A]]
  # ?(?a) --> ?a, ?(+a) --> ?a, +(?a) --> ?a
  [ [SHOULD, [SHOULD, A]]                    ,  [SHOULD, A]]
  [ [SHOULD, [MUST, A]]                      ,  [SHOULD, A]]
  [ [MUST, [SHOULD, A]]                      ,  [SHOULD, A]]
  # [?a] --> [+a]
  [ [SEQ, [SHOULD, A]]                       ,  [MUST, A]]

  # +(+a) --> +a, -(-a) --> +a
  [ [MUST, [MUST, A]]                        ,  [MUST, A]]
  [ [MUST_NOT, [MUST_NOT, A]]                ,  [MUST, A]]

  # "pull up"  occs
  [ [MUST, [DEFAULT, A]]        , [MUST,A]]
  [ [SHOULD, [DEFAULT, A]]      , [SHOULD,A]]
  [ [MUST_NOT, [DEFAULT, A]]    , [MUST_NOT,A]]
  [ [DEFAULT, [DEFAULT, A]]     , [DEFAULT,A]]

  # NOTE it is important to do this *AFTER* pull up
  # replace DEFAULT with SHOULD
  #[ [DEFAULT, A]                , [SHOULD, A]]
  [ [QLF, Q, [DEFAULT, A]]      , [DEFAULT,[QLF, Q,A]]]
  [ [QLF, Q, [MUST, A]]         , [MUST,[QLF, Q,A]]]
  [ [QLF, Q, [MUST_NOT, A]]     , [MUST_NOT,[QLF, Q,A]]]
  [ [QLF, Q, [SHOULD, A]]       , [SHOULD,[QLF, Q,A]]]


]

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
  # same occurence, this sequence can be inlined. I could not come up with a
  # clever way to represent this using pattern matching, so I wrote a messy little function
  # for this:
  inlineSeq
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
