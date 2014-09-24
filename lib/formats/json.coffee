
class Format

  constructor: (options) ->
    @skipOptional = options?.skipOptional or false

  prepareProperties: (primitive, properties, cb) ->
    props = []
    for prop in properties
      if prop.oneOf?.length > 0
        prop = prop.oneOf[0]
      props.push prop
    cb null, props

  handleOneOfProperties: (oneOf, properties, cb) ->
    cb null, properties

  handleOneOfElements: (oneOf, elements, cb) ->
    cb null, elements[0].repr

  handleObject: (primitive, properties, cb) ->
    obj = {}
    for {element, repr} in properties
      if element.templated or (@skipOptional and not element.required)
        continue
      obj[element.name] = repr
    cb null, obj

  handleArray: (primitive, elements, cb) ->
    cb null, (repr for {element, repr} in elements)

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
