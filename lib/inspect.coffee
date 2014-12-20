
# TODO this module should be tested properly


# Lists all defined non-sample values.
listValues = (type) ->
  (val.literal for val in (type.valueDefinition?.values or []) when not val.variable)


# Takes type node and lists its attributes, such as `required`, `fixed`, etc.
listTypeAttributes = (type) ->
  # the first one is for top-level 'named types', the other is for 'member types'
  (type.base or type.valueDefinition?.typeDefinition)?.attributes or []


# Convenience function.
isRequired = (type) ->
  'required' in listTypeAttributes type


# Convenience function.
isFixed = (type) ->
  'fixed' in listTypeAttributes type


# Takes object type node and lists its property nodes.
listPropertyTypes = (objectType) ->
  props = []
  for member in (objectType.sections or []) when member.type is 'member'
    props.push prop for prop in member.content when prop.type is 'property'
  props


# Takes array type node and lists its item nodes.
listItemTypes = (arrayType) ->
  items = []
  for member in (arrayType.sections or []) when member.type is 'member'
    items.push item for item in member.content when item.type is 'value'
  items


module.exports = {
  listTypeAttributes
  listPropertyTypes
  listItemTypes
  listValues
  isRequired
  isFixed
}
