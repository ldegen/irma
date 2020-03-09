
start = _ expr:Weak _ {return expr;}

// Please note the nameing conventions for rules:
// - non-terminals ending with ~Expression are concrete productions
// - non-terminals without the ~Expression ending are abstractions, i.e. groups of other rules.
// - terminals with ~Content describe the character content of some atomic node
// - terminals with ~Token are used for things like keywords or operator-tokens.

// The non-terminals Weak, StrongerThanOr, etc are used to 
// control the operator precedence

Weak
  = OrExpression
  / StrongerThanOr

StrongerThanOr
  = SequenceExpression
  / StrongerThanSequence
  
StrongerThanSequence
  = AndExpression
  / StrongerThanAnd
  
StrongerThanAnd
  = NotExpression
  / StrongerThanNot
  
StrongerThanNot
  = MustOccurExpression
  / MustNotOccurExpression
  / ShouldOccurExpression
  / StrongerThanOccurence

StrongerThanOccurence
  = QualifiedExpression
  / StrongerThanQualified
  
StrongerThanQualified
  = ParenthesizedExpression
  / Atomic
  
Atomic
  = QuotedLiteral
  / TermExpression
  
QuotedLiteral
  = DoubleQuotedLiteralExpression
  / SingleQuotedLiteralExpression
  
  
// next we define the production rules for compound expressions
// NOTE: ~Expression rules should not reference other ~Expression rules.
MustOccurExpression
  = '+' rhs:StrongerThanOccurence {return ['MUST', rhs]; }
MustNotOccurExpression
  = '-' rhs:StrongerThanOccurence {return ['MUST_NOT', rhs]; }
ShouldOccurExpression
  = '?' rhs:StrongerThanOccurence {return ['SHOULD', rhs]; }
  
QualifiedExpression
  = lhs:FieldNameToken ColonToken rhs:StrongerThanQualified {return ['QLF', lhs, rhs];}

SequenceExpression
  = seq:(_ elm:StrongerThanSequence {return elm;})+ {return seq.length>1  ? ['SEQ'].concat(seq) : seq[0];}

OrExpression
  = head:StrongerThanOr tail:(_ ORToken _ rhs:StrongerThanOr { return rhs;})+ {return ['OR',head].concat(tail);}

AndExpression
  = head:StrongerThanAnd tail:(_ ANDToken _ rhs:StrongerThanAnd { return rhs;})+ {return ['AND',head].concat(tail);}

NotExpression
  = NOTToken _ rhs:StrongerThanAnd { return ['NOT', rhs];}

ParenthesizedExpression
  = LParToken _ expr:Weak _ RParToken {return expr;}
  
// next there are the atomic expressions

TermExpression "_term"
  = !ANDToken !ORToken !NOTToken [^\t\n\r ()"?+\-\:]+ { return ['TERM',text().trim()];}

DoubleQuotedLiteralExpression
  = '"' content:DoubleQuotedLiteralContent* '"' {return ['DQUOT', content.join("")];} 

SingleQuotedLiteralExpression
  = '\'' content:SingleQuotedLiteralContent* '\'' {return ['SQUOT', content.join("")];} 

// Field Names are similar to Terms, but they are no Expression
FieldNameToken
  = [^\t\n\r ()"?+\-\:]+ { return text();}

// next we define the allowed content of string literals

DoubleQuotedLiteralContent
  = [^"\\]+ { return text(); }
  / '\\' c:[\"\'\\] {return c;}

SingleQuotedLiteralContent
  = [^'\\]+ { return text(); }
  / '\\' c:[\"\'\\] {return c;}



// finally keywords, operator tokens and whitespace

ANDToken "_and"
  = 'AND'

ORToken "_or"
  = 'OR'

NOTToken "_not"
  = 'NOT'
ColonToken "_col"
  = ':'
LParToken "_lpar"
  = '('
RParToken "_rpar"
  = ')'


_ "_whitespace"
  = [ \t\n\r]*
