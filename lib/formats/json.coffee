
class Format

  constructor: (options) ->
    @skipOptional = options?.skipOptional or false

  handleObject: (primitive, properties, cb) ->
    obj = {}
    for prop, i in primitive.value
      obj[prop.name] = properties[i]
    cb null, obj

  handleArray: (primitive, elements, cb) ->
    cb null, elements

  handleOneOfProperties: (element, properties, cb) ->
    cb null, properties[0]

  handleOneOfElements: (element, elements, cb) ->
    cb null, elements[0]

  handleString: (primitive, cb) ->
    cb null, primitive.value.toString()

  handleNumber: (primitive, cb) ->
    num = parseFloat primitive.value
    if not isNaN num
      cb null, num
    else
      cb new Error "Unable to convert to number: #{primitive.value}"

  handleBool: (primitive, cb) ->
    try
      cb null, !!JSON.parse primitive.value
    catch e
      cb new Error "Unable to convert to boolean: #{primitive.value}"

  handleNull: (cb) ->
    cb null, null


module.exports = {
  Format
}
