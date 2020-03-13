unparse = require "../src/ast-unparse.coffee"
{TERM, MUST,MUST_NOT,SHOULD,QLF,SEQ,OR,AND,NOT,DQUOT,SQUOT} = require "../src/ast-helper.coffee"
describe "The AST Unparser", ->
  it "knows how to represent simple and compound expressions", ->
    lhs = [TERM, 'lhs']
    rhs = [TERM, 'rhs']
    one = [TERM, 'one']
    two = [TERM, 'two']
    three = [TERM, 'three']

    expect(unparse [MUST, lhs]).to.eql "+lhs"
    expect(unparse [MUST_NOT, lhs]).to.eql "-lhs"
    expect(unparse [SHOULD, lhs]).to.eql "?lhs"
    expect(unparse [QLF,'name',lhs]).to.eql "name:lhs"
    expect(unparse [SEQ,one,two,three]).to.eql "one two three"
    expect(unparse [OR, one, two, three]).to.eql "one OR two OR three"
    expect(unparse [AND, one, two, three]).to.eql "one AND two AND three"
    expect(unparse [NOT, two]).to.eql "NOT two"

  it "knows how to represent quoted literals", ->
    expect(unparse [DQUOT, "yes, a \"quoted\" string"]).to.eql "\"yes, a \\\"quoted\\\" string\""
    expect(unparse [SQUOT, "with a \\backslash\\"]).to.eql "'with a \\\\backslash\\\\'"

  it "knows when to use parenthesis", ->
    one = [TERM, 'one']
    two = [TERM, 'two']
    three = [TERM, 'three']

    # this may seem counter-intuitive, but the parens are required here.
    # Understand that the parser would parse a AND b AND c into a single ternary AND node.
    # The equivalence between a AND b AND c and (a AND b) AND c only exists on 
    # a semantic level. As far as the unparser is concerned, these are *different terms*!
    expect(unparse [AND, [AND, one, two], three]).to.eql "(one AND two) AND three"

    # OTOH AND binds stronger than OR so here the unparser does indeed ommit the parens.
    expect(unparse [OR, [AND, one, two], three]).to.eql "one AND two OR three"
  
    # Here it is necessary again.
    expect(unparse [AND, [OR, one, two], three]).to.eql "(one OR two) AND three"

    expect(unparse [MUST,[SEQ, one,[QLF,"oink",two],three]]).to.eql "+(one oink:two three)"

