# Utility functions for inspecting the MSON AST tree


# Turns top-level *Named Type* into an *Element* carrying a *Value Member*.
getAsElement = (namedTypeNode) ->
  class: 'value'
  content:
    valueDefinition:
      typeDefinition: namedTypeNode.typeDefinition
    sections: namedTypeNode.sections


# Finds *typeSpecification* object for given *Element*.
findTypeSpecification = (elementNode) ->
  elementNode.content?.valueDefinition?.typeDefinition?.typeSpecification


# Finds type name within *typeSpecification* object.
findTypeName = (typeSpec) ->
  typeSpec?.name


# Finds type name within *Element* node of *property* class.
findPropertyName = (propNode, variable = true) ->
  nameNode = propNode.content.name
  nameNode.literal or (nameNode.variable?.values?[0].literal if variable)


# Lists all defined values.
listValues = (elementNode, excludeVariables = false) ->
  if excludeVariables
    filter = (val) -> not val.variable
  else
    filter = (val) -> true
  (elementNode.content.valueDefinition?.values or []).filter filter


# Takes *Element* node and lists its attributes, such as `required`, `fixed`, etc.
listAttributes = (elementNode) ->
  elementNode.content.valueDefinition?.typeDefinition?.attributes or []


# Convenience function.
isRequired = (elementNode) ->
  'required' in listAttributes elementNode


# Convenience function.
isFixed = (elementNode) ->
  'fixed' in listAttributes elementNode


# Convenience function.
isOrInheritsFixed = (elementNode, inherited) ->
  inherited.fixed or isFixed elementNode


# Helper function.
listNestedElements = (elementNode, classes) ->
  elements = []
  for section in (elementNode.content?.sections or []) when section.class is 'memberType'
    elements.push el for el in section.content when el.class in classes
  elements


# Takes *Element* carrying an object and lists its property nodes.
listProperties = (objectElementNode) ->
  listNestedElements objectElementNode, ['property', 'oneOf']


# Takes *Element* carrying an array and lists its item nodes.
listItems = (arrayElementNode) ->
  listNestedElements arrayElementNode, ['value']


# Takes type node and finds out whether it has more than one value
# in value definition.
hasMultipleValues = (elementNode) ->
  (elementNode.content?.valueDefinition?.values?.length or 0) > 1


# Takes element and finds out whether it has any sections containing member
# types.
hasAnyMemberSections = (elementNode) ->
  (section for section in (elementNode.content?.sections or []) when section.class is 'memberType').length


# Lists possible heritage objects {fixed, typeName} which can be applied to
# sub-members of given parent node. In most cases, the resulting array
# will contain just one item, but for some MSON constructs, such as
# `array[number,string]`, multiple options will be returned.
#
# The *resolvedType* argument is optional as nested types are relevant only
# for arrays and enums.
listPossibleHeritages = (fixed, resolvedType) ->
  return [{fixed}] unless resolvedType?.nested?.length
  ({fixed, typeName} for typeName in resolvedType.nested)


# Convenience function.
getHeritage = (fixed, resolvedType) ->
  listPossibleHeritages(fixed, resolvedType)?[0]


module.exports = {
  getAsElement
  findTypeSpecification
  findTypeName
  findPropertyName
  listAttributes
  listProperties
  listItems
  listValues
  isRequired
  isFixed
  isOrInheritsFixed
  hasMultipleValues
  hasAnyMemberSections
  listPossibleHeritages
  getHeritage
}
