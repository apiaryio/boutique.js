
{BaseFormat} = require './base'


class Format extends BaseFormat

  constructor: (options) ->
    @skipOptional = options?.skipOptional or false

  prepareObjectProperties: (primitive, properties, cb) ->
    props = []
    for prop in properties
      if prop.oneOf?.length > 0
        prop = prop.oneOf[0]
      props.push prop
    cb null, props

  prepareArrayElements: (primitive, elements, cb) ->
    elems = []
    for elem in elements
      if elem.oneOf?.length > 0
        elem = elem.oneOf[0]
      elems.push elem
    cb null, elems

  handleObject: (primitive, wrappedProperties, cb) ->
    obj = {}
    for {element, repr} in wrappedProperties
      if element.templated or (@skipOptional and not element.required)
        continue
      obj[element.name] = repr
    cb null, obj

  handleArray: (primitive, wrappedElements, cb) ->
    cb null, (repr for {element, repr} in wrappedElements)

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
