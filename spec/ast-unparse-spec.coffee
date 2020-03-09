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

    expect(unparse [AND, [AND, one, two], three]).to.eql "one AND two AND three"
    expect(unparse [AND, [OR, one, two], three]).to.eql "(one OR two) AND three"
    expect(unparse [OR, [AND, one, two], three]).to.eql "one AND two OR three"

    expect(unparse [MUST,[SEQ, one,[QLF,"oink",two],three]]).to.eql "+(one oink:two three)"

