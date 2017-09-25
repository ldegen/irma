
start = _ expr:Expression _ {return expr;}

Expression
  = Disjunctive

//The terms "disjunctive" and "conjunctive" are used to describe binding priority,
// not semantics! A "conjunctive" expression binds stronger than a "disjunctive" one. That's all.
Disjunctive
  = OrExpression
  / Sequence

Sequence
  = seq:(_ elm:SequenceElement {return elm;})+ {return seq.length>1  ? ['SEQ'].concat(seq) : seq[0];}

SequenceElement
  = Conjunctive
  / Terms
  
Conjunctive
  = AndExpression
  / Unary
  

Unary
  = NotExpression
  / Parenthesized
  

Operand
  = Unary
  / Term

OrExpression
  = head:Sequence tail:(_ OR _ rhs:Sequence { return rhs;})+ {return ['OR',head].concat(tail);}

AndExpression
  = head:Operand tail:(_ AND _ rhs:Operand { return rhs;})+ {return ['AND',head].concat(tail);}

NotExpression
  = NOT _ rhs:Operand { return ['NOT', rhs];}

Parenthesized
  = LPar _ expr:Expression _ RPar {return expr;}

Terms
  = terms:(_ !AndExpression !NotExpression t:Term{return t[1]})+ {return ['TERMS'].concat( terms);}

Term
  = term:Atom {return ['TERMS', term];} 


AND "_and"
  = 'AND'

OR "_or"
  = 'OR'

NOT "_not"
  = 'NOT'

LPar "_lpar"
  = '('
RPar "_rpar"
  = ')'

Atom "_atom"
  = !AND !OR !NOT [^\t\n\r ()]+ { return text().trim();}

_ "_whitespace"
  = [ \t\n\r]*
