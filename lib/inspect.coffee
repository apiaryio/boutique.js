
# TODO this module should be tested properly


# Finds *typeSpecification* object for given *Named Type* or *Property Member*
# or *Value Member*.
findTypeSpecification = (typeNode) ->
  if typeNode.base?.typeSpecification?
    # Top-level *Named Type* node.
    typeNode.base.typeSpecification
  else
    # *Property Member* or *Value Member* node
    typeNode.valueDefinition?.typeDefinition?.typeSpecification


# Finds type name within *typeSpecification* object.
findTypeName = (typeSpec) ->
  typeSpec?.name?.name


# Lists all defined values.
listValues = (typeNode, excludeVariables = false) ->
  if excludeVariables
    filter = (val) -> not val.variable
  else
    filter = (val) -> true

  (typeNode.valueDefinition?.values or []).filter filter


# Takes type node and lists its attributes, such as `required`, `fixed`, etc.
listAttributes = (typeNode) ->
  # the first one is for top-level 'named types', the other is for 'member types'
  (typeNode.base or typeNode.valueDefinition?.typeDefinition)?.attributes or []


# Convenience function.
isRequired = (typeNode) ->
  'required' in listAttributes typeNode


# Convenience function.
isFixed = (typeNode) ->
  'fixed' in listAttributes typeNode


# Takes object type node and lists its property nodes.
listPropertyNodes = (objectTypeNode) ->
  props = []
  for member in (objectTypeNode.sections or []) when member.type is 'member'
    props.push prop for prop in member.content when prop.type is 'property'
  props


# Takes array type node and lists its item nodes.
listItemNodes = (arrayTypeNode) ->
  items = []
  for member in (arrayTypeNode.sections or []) when member.type is 'member'
    items.push item for item in member.content when item.type is 'value'
  items


module.exports = {
  findTypeSpecification
  findTypeName
  listAttributes
  listPropertyNodes
  listItemNodes
  listValues
  isRequired
  isFixed
}
