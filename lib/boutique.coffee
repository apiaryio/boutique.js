

class Boutique

  constructor: (@format, options) ->
    @skipOptional = options?.skipOptional or false

  # Traverses the AST tree and provides its complete representation.
  represent: (ast, cb) ->
    ast = ast or {}
    try
      cb null, @handleElement ast
    catch err
      cb err, null

  handleElement: (element) ->
    @validateElement element

    if element.oneOf?.length > 0
      return @handleOneOf element.oneOf
    if element.ref?
      return @handleRef element.ref

    if not element.primitive?.value
      return @format.representNull()
    @handlePrimitive element.primitive

  validateElement: (element) ->
    # check mutally exclusive properties
    present = []
    for prop in ['primitive', 'oneOf', 'ref']
      if element[prop]?
        present.push prop
    if present.length > 1
      present = ("'#{prop}'" for prop in present).join ', '
      throw new Error "Following properties are mutually exclusive: #{present}."

  handlePrimitive: ({value, type}) ->
    type = type or (if Array.isArray value then 'object')

    if type is 'object'
      @format.representObject @handleProperties value

    else if type is 'array'
      @format.representArray (
        @handleElement elem for elem in value
      )

    else if type is 'number'
      @format.representNumber value

    else if type in ['bool', 'boolean']
      @format.representBool value

    else  # string
      @format.representString value

  handleOneOf: (oneOf) ->
    @handleElement element.oneOf[0]  # choose the first one

  handleRef: (ref) ->
    throw new Error "Property 'ref' is not implemented yet. https://github.com/apiaryio/boutique/issues"

  handleProperties: (properties) ->
    represented = []
    for prop in properties
      if not prop.required and @skipOptional
        continue
      if prop.templated
        continue
      represented.push @handleProperty prop
    represented

  handleProperty: (property) ->
    @format.representObjectProperty property.name, @handleElement property


module.exports = {
  Boutique
}
