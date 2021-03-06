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
  nameNode.literal or (nameNode.variable?.values?[0]?.literal if variable)


# Finds inline description for given *Element* node.
findDescription = (elementNode) ->
  elementNode.content?.description


# Finds default for given *Element* node.
findDefault = (elementNode) ->
  items = listNestedElements elementNode, ['default'], ['value']
  if items.length
    vals = listValues items[0]
  else if 'default' in listAttributes elementNode
    vals = listValues elementNode
  else
    return null
  vals?[0]


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


# Lists all samples for given *Element* node.
listSamples = (elementNode) ->
  vals = []
  items = listNestedElements elementNode, ['sample'], ['value']
  if items.length
    vals = vals.concat listValues(item) for item in items
  else if 'sample' in listAttributes elementNode
    vals = listValues elementNode
  else
    vals = listVariableValues elementNode
  return vals


# Lists all values and if no values are present, lists all samples.
listValuesOrSamples = (elementNode) ->
  vals = listValues elementNode
  vals = listSamples elementNode unless vals.length
  vals


# Takes *Element* node and lists its attributes, such as `required`, `fixed`, etc.
listAttributes = (elementNode) ->
  elementNode.content.valueDefinition?.typeDefinition?.attributes or []


# Provides information whether given *Element* node is required or not.
# For property nodes it's possible to pass also heritage object - in that
# case the function respects also `fixed`, etc.
isRequired = (elementNode, heritage={}) ->
  return true if 'required' in listAttributes elementNode
  isOrInheritsFixed(elementNode, heritage) and not isOptional(elementNode)


# Convenience function.
isOptional = (elementNode) ->
  'optional' in listAttributes elementNode


# Convenience function.
isFixed = (elementNode) ->
  'fixed' in listAttributes elementNode


# Convenience function.
isSample = (elementNode) ->
  'sample' in listAttributes elementNode


# Convenience function.
isOrInheritsFixed = (elementNode, inherited) ->
  inherited.fixed or isFixed elementNode


# Convenience function.
isPrimitive = (typeName) ->
  typeName in primitiveTypes


# Helper function.
listNestedElements = (elementNode, sectionClasses, elementClasses) ->
  elements = []
  for section in (elementNode.content?.sections or []) when section.class in sectionClasses
    if section.content?
      elements.push el for el in section.content when el.class in elementClasses
  elements


# Takes *Element* carrying an object and lists its property nodes.
listProperties = (objectElementNode) ->
  listNestedElements objectElementNode, ['memberType'], ['property', 'oneOf']


# Takes *Element* carrying an array and lists its item nodes.
listItems = (arrayElementNode) ->
  listNestedElements arrayElementNode, ['memberType'], ['value']


# Convenience function.
hasVariableValues = (elementNode) ->
  !!listVariableValues(elementNode).length


# Convenience function.
haveVariableValues = (elementNodes) ->
  return true for elementNode in elementNodes when hasVariableValues elementNode
  false


# Takes type node and finds out whether it has more than one value
# in value definition.
hasMultipleValues = (elementNode) ->
  (elementNode.content?.valueDefinition?.values?.length or 0) > 1


# Takes element and finds out whether it has any sections containing member
# types.
hasAnyMemberSections = (elementNode) ->
  (section for section in (elementNode.content?.sections or []) when section.class is 'memberType').length


# Detects whether given *Element* node of *property* class has
# variable property name.
hasVariablePropertyName = (propNode) ->
  nameNode = propNode.content.name
  not nameNode.literal and nameNode.variable?.values?.length


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
  findDescription
  findDefault
  listAttributes
  listProperties
  listItems
  listValues
  listVariableValues
  listSamples
  listValuesOrSamples
  isRequired
  isOptional
  isFixed
  isSample
  isOrInheritsFixed
  isPrimitive
  hasVariableValues
  haveVariableValues
  hasMultipleValues
  hasAnyMemberSections
  hasVariablePropertyName
  listPossibleHeritages
  getHeritage
}
