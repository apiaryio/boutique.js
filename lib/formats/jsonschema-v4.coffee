
{BaseFormat} = require './base'


addDescription = (element, schema) ->
  if element.description
    schema.description = element.description
  schema


class Format extends BaseFormat

  handleObject: (element, wrappedProperties, cb) ->
    schema =
      type: 'object'
      properties: {}

    required = []
    additional = false

    for {subElement, repr} in wrappedProperties
      if subElement.templated
        additional = true
      else
        if subElement.required
          required.push subElement.name
        schema.properties[subElement.name] = repr

    if required.length
      schema.required = required
    if not additional
      schema.additionalProperties = false

    cb null, addDescription element, schema

  handleOneOfProperties: (element, wrappedProperties, cb) ->
    cb new Error "Unfortunatelly, oneOf for object properties is not implemented yet."

  handleArray: (element, wrappedElements, cb) ->
    cb null, addDescription element,
      type: 'array'
      items: (repr for {subElement, repr} in wrappedElements)

  handleOneOfElements: (element, wrappedElements, cb) ->
    cb null, addDescription element,
      oneOf: (repr for {subElement, repr} in wrappedElements)

  handleString: (element, cb) ->
    cb null, addDescription element,
      type: 'string'

  handleNumber: (element, cb) ->
    cb null, addDescription element,
      type: 'number'

  handleBool: (element, cb) ->
    cb null, addDescription element,
      type: 'boolean'

  handleNull: (element, cb) ->
    cb null, addDescription element, {}


module.exports = {
  Format
}
