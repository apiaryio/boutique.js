
class BaseFormat

  constructor: (options) ->

  prepareObjectProperties: (primitive, properties, cb) ->
    cb null, properties

  handleObject: (primitive, wrappedProperties, cb) ->
    cb new Error 'Not implemented.'

  prepareArrayElements: (primitive, elements, cb) ->
    cb null, elements

  handleArray: (primitive, wrappedElements, cb) ->
    cb new Error 'Not implemented.'

  prepareOneOfProperties: (oneOf, properties, cb) ->
    cb null, properties

  handleOneOfProperties: (oneOf, wrappedProperties, cb) ->
    cb new Error 'Not implemented.'

  prepareOneOfElements: (oneOf, elements, cb) ->
    cb null, elements

  handleOneOfElements: (oneOf, wrappedElements, cb) ->
    cb new Error 'Not implemented.'

  handleString: (primitive, cb) ->
    cb new Error 'Not implemented.'

  handleNumber: (primitive, cb) ->
    cb new Error 'Not implemented.'

  handleBool: (primitive, cb) ->
    cb new Error 'Not implemented.'

  handleNull: (cb) ->
    cb new Error 'Not implemented.'


module.exports = {
  BaseFormat
}
