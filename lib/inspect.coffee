
# Takes type node and lists its attributes, such as `required`, `fixed`, etc.
listTypeAttributes = (type) ->
  # the first one is for top-level 'named types', the other is for 'member types'
  (type.base or type.valueDefinition?.typeDefinition)?.attributes or []


# Takes object type node and lists its property nodes.
listProperties = (objectType) ->
  props = []
  for member in (objectType.sections or []) when member.type is 'member'
    props.push prop for prop in member.content when prop.type is 'property'
  props


# Takes array type node and lists its value nodes.
listValues = (arrayType) ->
  vals = []
  for member in (arrayType.sections or []) when member.type is 'member'
    vals.push val for val in member.content when val.type is 'value'
  vals


module.exports = {
  listTypeAttributes
  listProperties
  listValues
}
