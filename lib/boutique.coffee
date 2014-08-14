

class Boutique

  constructor: (@format, options) ->
    @skipOptional = options?.skipOptional ? false
    @skipTemplated = options?.skipTemplated ? true

  # Traverses the AST tree and provides its complete representation.
  represent: (ast, cb) ->
    try
      cb null, @handleElement ast
    catch err
      cb err, null

  validateElement: (element) ->
    # mutally exclusive properties
    present = []
    for prop in ['primitive', 'oneOf', 'ref']
      if element[prop]?
        present.push prop
    if present.length > 1
      present = ("'#{prop}'" for prop in present).join ', '
      throw new Error "Following properties are mutually exclusive: #{present}."

  handleElement: (element) ->
    @validateElement element

    if element.oneOf?.length > 0
      return @handleOneOf element.oneOf
    if element.ref?
      return @handleRef element.ref

    if not element.primitive?.value
      return @format.representNull()
    @handlePrimitive element.primitive

  handlePrimitive: ({value, type}) ->
    type = type ? if Array.isArray value then 'object' else 'string'

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

  handleProperty: (property) ->
    @format.representObjectProperty property.name, @handleElement property

  handleProperties: (properties) ->
    represented = []
    for prop in properties
      if not prop.required and @skipOptional
        continue
      if prop.templated and @skipTemplated
        continue
      represented.push @handleProperty prop
    represented


module.exports = {
  Boutique
}
