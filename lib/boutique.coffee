
# TODO:
# * error handling
# * representer should validate the AST
class Boutique

  constructor: (@format, options) ->
    @skipOptional = options?.skipOptional ? true
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

    if element.primitive?
      prim = element.primitive

      if not prim.type or not prim.value
        # TODO we don't know either type or the value
        # - should we skip the property?
        # TODO and what about having only one of them?
        return null

      if prim.type is 'object'
        return @format.representObject @handleProperties prim.value

      else if prim.type is 'array'
        return @format.representArray (
          @handleElement elem for elem in prim.value
        )

      else if prim.type is 'string'
        return @format.representString prim.value

      else if prim.type is 'number'
        return @format.representNumber prim.value

      else if prim.type in ['bool', 'boolean']
        return @format.representBool prim.value

      else
        # TODO we don't know the type
        # - should we imply string or to skip the property?
        return null

    if element?.oneOf?.length > 0
      return @handleElement element.oneOf[0]  # choose the first one

    if element.ref?
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
