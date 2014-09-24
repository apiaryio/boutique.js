
async = require 'async'


class Boutique

  constructor: (@format) ->

  represent: (ast, cb) ->
    @traverseElement ast or {}, false, cb

  traverseElement: (element, isProperty, cb) ->
    @validateElement element, (err) =>
      if err then return cb err

      if element.oneOf?.length > 0
        async.map element.oneOf
        , (item, next) =>
          @traverseElement item, isProperty, (err, repr) ->
            next err, {element: item, repr}
        , (err, items) =>
          if err then return cb err
          if isProperty
            @format.handleOneOfProperties element.oneOf, items, cb
          else
            @format.handleOneOfElements element.oneOf, items, cb

      else if element.ref?
        # when implementing this, beware: referencing can be recursive
        cb new Error "Referencing is not implemented yet."

      else if not element.primitive?.value
        @format.handleNull cb

      else
        @traversePrimitive element.primitive, cb

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

  traversePrimitive: (primitive, cb) ->
    value = primitive.value
    type = primitive.type or (
      if Array.isArray value then 'object' else 'string'
    )

    if type is 'object'
      @format.prepareProperties primitive, value, (err, properties) =>
        async.map properties
        , (prop, next) =>
          @traverseElement prop, true, (err, repr) =>
            next err, {element: prop, repr}
        , (err, properties) =>
          if err then return cb err
          @format.handleObject primitive, properties, cb

    else if type is 'array'
      async.map value
      , (elem, next) =>
        @traverseElement elem, false, (err, repr) =>
          next err, {element: elem, repr}
      , (err, elements) =>
        if err then return cb err
        @format.handleArray primitive, elements, cb

    else if type is 'number'
      @format.handleNumber primitive, cb

    else if type in ['bool', 'boolean']
      @format.handleBool primitive, cb

    else  # string
      @format.handleString primitive, cb


module.exports = {
  Boutique
}
