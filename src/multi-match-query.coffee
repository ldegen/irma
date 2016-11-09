module.exports = (opts0)->
  isArray = require('util').isArray
  opts = opts0
  transformers =
    TERMS: (operands)->
      multi_match:
        query: operands.join ' '
        type: 'cross_fields'
        fields: if isArray(opts.fields) then opts.fields else ("#{fieldName}^#{boost}" for fieldName, boost of opts.fields)
        operator: 'and'
    OR: (operands) ->
      bool:
        should: operands.map transform
    AND: (operands) ->
      bool:
        must: operands.map transform
    NOT: (operands) ->
      bool:
        must_not: operands.map transform
    SEQ: (operands) ->
      bool:
        must: operands.map transform


  transform = (ast)-> transformers[ast[0]] ast.slice 1

