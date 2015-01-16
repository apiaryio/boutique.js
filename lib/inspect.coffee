# Utility functions for inspecting the MSON AST tree


# Listing of all primitive types as defined in MSON AST spec.
primitiveTypes = ['boolean', 'string', 'number']


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


# Lists all defined variable values.
listVariableValues = (elementNode) ->
  (val for val in (elementNode.content.valueDefinition?.values or []) when val.variable)


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


# Convenience function.
hasVariableValues = (elementNode) ->
  !!listVariableValues(elementNode).length


# Convenience function.
haveVariableValues = (elementNodes) ->
  for elementNode in elementNodes
    if hasVariableValues elementNode
      return true
  false


# Takes type node and finds out whether it has more than one value
# in value definition.
hasMultipleValues = (elementNode) ->
  (elementNode.content?.valueDefinition?.values?.length or 0) > 1


# Takes element and finds out whether it has any sections containing member
# types.
hasAnyMemberSections = (elementNode) ->
  (section for section in (elementNode.content?.sections or []) when section.class is 'memberType').length


# Returns true in case all given type names are the same and at the same time
# they're also primitive.
areIdenticalAndPrimitive = (typeNames) ->
  first = typeNames[0]
  return false unless first in primitiveTypes
  for typeName in typeNames
    return false if typeName isnt first
  true


# Lists possible 'heritage objects' which can be applied to
# sub-members of given parent node. In most cases, the resulting array
# will contain just one item, but for some MSON constructs, such as
# `array[number,string]`, multiple options will be returned.
#
# The *resolvedType* argument is optional as nested types are relevant only
# for arrays and enums.
#
# Heritage object explanation:
#
# - fixed (boolean) - whether `fixed` flag is inherited
# - parentTypeName (string) - type name of the parent container
# - typeName (string) - inherited nested type name (for arrays and enums only)
listPossibleHeritages = (fixed, resolvedType) ->
  parentTypeName = resolvedType?.name or null  # intentionally not using `undefined` as "valid value"
  nested = if resolvedType?.nested?.length then resolvedType.nested else [null]
  {fixed, typeName, parentTypeName} for typeName in nested


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
  listVariableValues
  isRequired
  isFixed
  isOrInheritsFixed
  hasVariableValues
  haveVariableValues
  hasMultipleValues
  hasAnyMemberSections
  areIdenticalAndPrimitive
  listPossibleHeritages
  getHeritage
}
