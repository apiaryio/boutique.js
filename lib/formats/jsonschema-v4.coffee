
{BaseFormat} = require './base'


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

    cb null, schema

  handleArray: (element, wrappedElements, cb) ->
    schema =
      type: 'array'
      items: (repr for {subElement, repr} in wrappedElements)

    if element.description
      schema.description = element.description

    cb null, schema

  handleString: (element, cb) ->
    schema =
      type: 'string'

    if element.description
      schema.description = element.description

    cb null, schema

  handleNumber: (element, cb) ->
    schema =
      type: 'number'

    if element.description
      schema.description = element.description

    cb null, schema

  handleBool: (element, cb) ->
    schema =
      type: 'boolean'

    if element.description
      schema.description = element.description

    cb null, schema

  handleNull: (cb) ->
    cb null, {}


module.exports = {
  Format
}
