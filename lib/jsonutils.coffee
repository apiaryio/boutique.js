# Utility functions for generating JSON-based formats


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


module.exports = {
  coerceLiteral
}
