
async = require 'async'


class Boutique

  constructor: (@format) ->

  represent: (ast, cb) ->
    @traverseElement ast or {}, false, cb

  traverseElement: (element, isProperty, cb) ->
    @validateElement element, (err) =>
      if err then return cb err

      if element.oneOf?.length > 0
        if isProperty
          funcs =
            prepare: 'prepareOneOfProperties'
            handle: 'handleOneOfProperties'
        else
          funcs =
            prepare: 'prepareOneOfElements'
            handle: 'handleOneOfElements'
        @traverseComposite element, element.oneOf, isProperty, funcs, cb

      else if element.ref?
        # when implementing this, beware: referencing can be recursive
        cb new Error "Referencing is not implemented yet."

      else if not element.primitive?
        @format.handleNull element, cb

      else
        @traversePrimitive element, cb

  validateElement: (element, cb) ->
    # check mutally exclusive properties
    present = []
    for prop in ['primitive', 'oneOf', 'ref']
      if element[prop]?
        present.push prop
    if present.length > 1
      present = ("'#{prop}'" for prop in present).join ', '
      cb new Error "Following properties are mutually exclusive: #{present}."
    else
      cb()

  traversePrimitive: (element, cb) ->
    value = element.primitive.value
    type = element.primitive.type or (
      if Array.isArray value then 'object' else 'string'
    )

    if type is 'object'
      @traverseComposite element, value, true,
        prepare: 'prepareObjectProperties'
        handle: 'handleObject'
      , cb

    else if type is 'array'
      @traverseComposite element, value, false,
        prepare: 'prepareArrayElements'
        handle: 'handleArray'
      , cb

    else if type is 'number'
      @format.handleNumber element, cb

    else if type in ['bool', 'boolean']
      @format.handleBool element, cb

    else  # string
      @format.handleString element, cb

  traverseComposite: (parent, subElements, areProperties, funcs, cb) ->
    @format[funcs.prepare] parent, subElements or [], (err, subElements) =>
      async.map subElements
      , (subElement, next) =>
        @traverseElement subElement, areProperties, (err, repr) ->
          next err, {subElement, repr}  # wrapping every subElement
      , (err, wrappedSubElements) =>
        if err then return cb err
        @format[funcs.handle] parent, wrappedSubElements, cb


module.exports = {
  Boutique
}
