
unparse = require "../src/ast-unparse.coffee"
{star, simplify, Normalize} = require "../src/ast-rewrite-rules.coffee"
{parse} = require "../src/query-parser.coffee"
{match, find} = require "../src/ast-matcher.coffee"
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
normalize = Normalize "SHOULD"

A = [VAR,'A']
As = [VARS,'As']
B = [VAR,'B']
Bs = [VARS,'Bs']

# NOTE: this is not a unit test, but an integration test
# that verifies certain properties of the complete chain
#
#  parse --> rewrite/simplify [ --> unparse ]
#
# The last step is skipped in some cases where we want to verify
# properties of the rewritten AST that are not visible in the
# stringified output.
#

test = it
describe "AST Rewrite Rules", ->

  astFor = (s)->
    orig = parse s
    {value:normalized} = normalize orig
    {value:simplified} = star(simplify) normalized
    #console.log "orig", orig
    #console.log "normalized", JSON.stringify normalized, null, "  "
    #console.log "simplified", JSON.stringify simplified, null, "  "
    simplified
  process = (s)->unparse astFor s
  head = (t)->if Array.isArray(t) then t[0]

  test "The root is always a SEQ node", ->
    expect(head(astFor('foo'))).to.equal "SEQ"
    expect(head(astFor('a AND NOT b'))).to.equal "SEQ"
    expect(head(astFor('NOT(a AND NOT b)'))).to.equal "SEQ"
    expect(head(astFor('-b'))).to.equal "SEQ"
    expect(head(astFor('?b'))).to.equal "SEQ"
    expect(head(astFor('42:b'))).to.equal "SEQ"

  test "Occurence annotations can only appear as child of a SEQ node" ,->
    expect(process("ast:(-(-(42)))")).to.equal "+ast:42"
    expect(process("+(NOT foo:bar)")).to.eql "-foo:bar"
    # FIXME: since we currently do not have a SHOULD_NOT expression occurence,
    #        we cannot simplify ?(-b) atm.
    expect(process("a OR NOT b")).to.eql "?a ?(-b)"

  test "Every child of a SEQ node must be an occurence annotation", ->
    expect(process "a").to.eql "+a"
    expect(process "-a").to.eql "-a"
    expect(process "-(-a)").to.eql "+a"
    expect(process "+(-a)").to.eql "-a"
    expect(process "-(+a)").to.eql "-a"
    expect(process "?a").to.eql "+a"
    expect(process "?(?a)").to.eql "+a"
    expect(process "?(+a)").to.eql "+a"
    expect(process "+(?a)").to.eql "+a"
    expect(process "-(?a)").to.eql "-a"
    expect(process "?(-a)").to.eql "-a"
    expect(process "a b c").to.eql "?a ?b ?c"
    expect(process "a +b").to.eql "?a +b"
    expect(process "a 42:b 13:(c +d)").to.eql "?a ?42:b ?13:(?c +d)"

  test "All boolean expressions are eliminated", ->
    expect(process "NOT (b OR c)").to.eql "-b -c"
    expect(process "a AND (b OR c) OR NOT e").to.equal "?(+a +(?b ?c)) ?(-e)"

  test "A SEQ node can only be a singleton if it is the root node", ->
    s =  "NOT a (foo:(NOT x:(-bar)))"
    expect(process s).to.eql "?(-a) ?foo:(x:bar)"
    # verify that there is only one SEQ node and that it is the root
    hits = find [SEQ,As], astFor s
    expect(hits.length).to.eql 1
    expect(hits[0].path).to.eql []

  test "MUST-chains are inlined", ->
    expect(process "+(+a +b) ?c +(+d +e +f) +(g +h)").to.eql "+a +b ?c +d +e +f +(?g +h)"

  test "SHOULD-chains are inlined", ->
    expect(process "(a (b (c d e) f) g h)").to.eql "?a ?b ?c ?d ?e ?f ?g ?h"

  test "Positive MUST/MUST_NOT-sequences are inlined", ->
    expect(process "a +(-b +c) d").to.eql "?a -b +c ?d"

  test "SHOULD_NOT-sequences are factored out (De Morgan 1)", ->
    expect(process "?(-a) ?(-b) ?(-c)").to.eql "-(+a +b +c)"

  test "Negative SHOULD-sequences are inlined (De Morgan 2)", ->
    expect(process "-(?a ?b ?c)").to.eql "-a -b -c"

