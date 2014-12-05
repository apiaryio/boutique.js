
async = require 'async'
{resolveType} = require '../typeResolution'


###########################################################################
## PROTOTYPE ALERT! This is work in progress as much as it only can be.  ##
###########################################################################


handleValue = (value, options, cb) ->
  resolveType value, (err, typeSpec) ->
    return cb err if err

    valueType = typeSpec.name  # ignoring nested types for now
    unless valueType
      if value.valueDefinition?.values?.length > 1
        valueType = 'array'
      else
        valueType = 'string'

    switch valueType
      when 'object'
        return handleObject value, options, cb

      # when 'array'
      #   do nothing - not implemented yet

    cb null, type: valueType


handleObject = (type, options, cb) ->
  # prepare a simple array of property objects
  props = []

  for member in (type.sections or []) when member.type is 'member'
    for prop in member.content when prop.type is 'property'
      props.push prop

  # map over that array, get representations of property values and wrap them
  # with object carrying also property-specific information (name, required, ...)
  async.map props, (prop, next) ->
    handleValue prop.content, options, (err, propRepr) ->
      next err,
        name: prop.content.name.literal
        repr: propRepr
        required: 'required' in (prop.content?.valueDefinition?.typeDefinition?.attributes or [])

  , (err, reprWrappers) ->
    return cb err if err

    # prepare containers for the final representation of the object
    propsRepr = {}
    requiredRepr = []

    # unwrap info for each property and render what needs to be rendered
    for {name, repr, required} in reprWrappers
      propsRepr[name] = repr
      requiredRepr.push name if required

    # build the final object representation and send it to callback
    repr =
      type: 'object'
      properties: propsRepr
    repr.required = requiredRepr if requiredRepr.length > 0
    cb null, repr


transform = (type, options, cb) ->
  handleObject type, options, (err, repr) ->
    return cb err if err
    repr["$schema"] = "http://json-schema.org/draft-04/schema#"
    cb null, repr


module.exports = {
  transform
}
