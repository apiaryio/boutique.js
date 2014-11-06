
traverse = require 'traverse'


transform = (type, symbolTable, options, cb) ->
  # TODO
  # - vyresit dedicnost, includes, aby format dostal cisty typ, ktery nejak
  #   vyrenderuje (z vysledku si schema vezme jen to co potrebuje),
  #   rekurzivne (?) pro kazdy vnoreny typ (?)
  # - pak vyhodit genericke veci do utils

  required = []
  properties = {}

  for member in type.sections when member.type is 'member'
    for property in member.content when property.type is 'property'
      # getting information about given member
      propName = property.content.name.literal
      propType = property.content?.valueDefinition?.typeDefinition?.typeSpecification?.name

      if not propType
        if property.content?.valueDefinition?.values?.length > 1
          propType = 'array'
        else
          propType = 'string'

      propRequired = 'required' in (property.content?.valueDefinition?.typeDefinition?.attributes or [])

      # rendering the member
      properties[propName] = type: propType
      if propRequired then required.push propName

  repr = {type: 'object', properties}
  if required.length > 0 then repr.required = required

  cb null, repr


module.exports = {
  transform
}
