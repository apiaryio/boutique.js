
{BaseFormat} = require './base'


class Format extends BaseFormat

  constructor: (options) ->
    @skipOptional = options?.skipOptional or false

  prepareObjectProperties: (element, properties, cb) ->
    props = []
    for prop in properties
      if prop.oneOf?.length > 0
        prop = prop.oneOf[0]
      props.push prop
    cb null, props

  prepareArrayElements: (element, elements, cb) ->
    elems = []
    for elem in elements
      if elem.oneOf?.length > 0
        elem = elem.oneOf[0]
      elems.push elem
    cb null, elems

  handleObject: (element, wrappedProperties, cb) ->
    if wrappedProperties.length
      obj = {}
      for {subElement, repr} in wrappedProperties
        if subElement.templated or (@skipOptional and not subElement.required)
          continue
        obj[subElement.name] = repr
      cb null, obj
    else
      @handleNull cb

  handleArray: (element, wrappedElements, cb) ->
    if wrappedElements.length
      cb null, (repr for {subElement, repr} in wrappedElements)
    else
      @handleNull cb

  handleString: (element, cb) ->
    if element.primitive.value?
      cb null, element.primitive.value.toString()
    else
      @handleNull cb

  handleNumber: (element, cb) ->
    if element.primitive.value?
      num = parseFloat element.primitive.value
      if not isNaN num
        cb null, num
      else
        cb new Error "Unable to convert to number: #{element.primitive.value}"
    else
      @handleNull cb

  handleBool: (element, cb) ->
    if element.primitive.value?
      try
        cb null, !!JSON.parse element.primitive.value
      catch e
        cb new Error "Unable to convert to boolean: #{element.primitive.value}"
    else
      @handleNull cb

  handleNull: (cb) ->
    cb null, null


module.exports = {
  Format
}
