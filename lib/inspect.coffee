
# TODO this module should be tested properly


# Finds *typeSpecification* object for given *Named Type* or *Property Member*
# or *Value Member*.
findTypeSpecification = (typeNode) ->
  if typeNode.typeDefinition?.typeSpecification?
    # Top-level *Named Type* node.
    typeNode.typeDefinition.typeSpecification
  else
    # *Property Member* or *Value Member* node
    typeNode.valueDefinition?.typeDefinition?.typeSpecification


# Finds type name within *typeSpecification* object.
findTypeName = (typeSpec) ->
  typeSpec?.name


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
  (typeNode.typeDefinition or typeNode.valueDefinition?.typeDefinition)?.attributes or []


# Convenience function.
isRequired = (typeNode) ->
  'required' in listAttributes typeNode


# Convenience function.
isFixed = (typeNode) ->
  'fixed' in listAttributes typeNode


# Takes object type node and lists its property nodes.
listPropertyNodes = (objectTypeNode) ->
  props = []
  for section in (objectTypeNode.sections or []) when section.class is 'memberType'
    props.push element for element in section.content when element.class is 'property' or 'oneof'
  props


# Takes array type node and lists its item nodes.
listItemNodes = (arrayTypeNode) ->
  items = []
  for section in (arrayTypeNode.sections or []) when section.class is 'memberType'
    items.push element for element in section.content when element.class is 'value'
  items


# Takes type node and finds out whether it has more than one value
# in value definition.
hasMultipleValues = (typeNode) ->
  (typeNode.valueDefinition?.values?.length or 0) > 1


# Takes type node and finds out whether it has any sections containing member
# types.
hasAnyMemberSections = (typeNode) ->
  (section for section in (typeNode.sections or []) when section.class is 'memberType').length


module.exports = {
  findTypeSpecification
  findTypeName
  listAttributes
  listPropertyNodes
  listItemNodes
  listValues
  isRequired
  isFixed
  hasMultipleValues
  hasAnyMemberSections
}
