

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

  handleElement: (element, isProperty) ->
    @validateElement element

    if element.oneOf?.length > 0
      value = @handleOneOf element.oneOf, isProperty
      if isProperty then return value  # we already got the whole prop rendered

    else if element.ref?
      value = @handleRef element.ref

    else if not element.primitive?.value
      value = @format.representNull()

    else
      value = @handlePrimitive element.primitive

    # if the element is also a property, we need to render it as such
    if isProperty
      @format.representObjectProperty element.name, value
    else
      value

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

  handleOneOf: (oneOf, isProperty) ->
    if isProperty
      if not @format.representOneOfProperties?
        return @handleProperty oneOf[0]

      @format.representOneOfProperties (
        @handleProperty prop for prop in oneOf
      )
    else
      if not @format.representOneOfElements?
        return @handleElement oneOf[0]

      @format.representOneOfElements (
        @handleElement elem for elem in oneOf
      )

  handleRef: (ref) ->
    # when implementing this, beware: referencing can be recursive
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
    @handleElement property, true


module.exports = {
  Boutique
}
