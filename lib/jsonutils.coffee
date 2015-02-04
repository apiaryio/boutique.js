# Utility functions for generating JSON-based formats


{detectSuccessful} = require './utils'


# Takes literal and MSON type and provides JSON value in corresponding type.
coerceLiteral = (literal, typeName, cb) ->
  switch typeName
    when 'string'
      cb null, literal
    when 'number'
      return cb new Error "Literal '#{literal}' is not a number." if isNaN literal
      cb null, parseFloat literal, 10
    when 'boolean'
      return cb new Error "Literal '#{literal}' is not 'true' or 'false'." if literal not in ['true', 'false']
      cb null, literal is 'true'
    else
      cb new Error "Literal '#{literal}' can't have type '#{typeName}'."


# Takes literal and MSON types and provides JSON value in
# the corresponding type, which is the first to be able to successfully
# perfom the coercion.
#
# This allows us to correctly coerce in situations like `array[number, string]`
# with items `hello, 1, 2, world`, where coercion to `number` throws errors,
# but coercion to `string` is perfectly valid result.
coerceNestedLiteral = (literal, typeNames, cb) ->
  detectSuccessful typeNames, (typeName, next) ->
    coerceLiteral literal, typeName, next
  , cb


module.exports = {
  coerceLiteral
  coerceNestedLiteral
}
