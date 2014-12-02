
async = require 'async'


###########################################################################
## PROTOTYPE ALERT! This is work in progress as much as it only can be.  ##
###########################################################################


handleValue = (value, symbolTable, options, cb) ->
  valueType = value.base?.typeSpecification?.name  # for top-level objects
  valueType = valueType or value.content?.valueDefinition?.typeDefinition?.typeSpecification?.name

  if not valueType
    if value.content?.valueDefinition?.values?.length > 1
      valueType = 'array'
    else
      valueType = 'string'

  switch valueType
    when 'object'
      return handleObject value.content, symbolTable, options, cb

    # when 'array'
    #   do nothing - not implemented yet

  cb null, type: valueType


handleObject = (type, symbolTable, options, cb) ->
  # prepare a simple array of property objects
  props = []

  for member in type.sections when member.type is 'member'
    for prop in member.content when prop.type is 'property'
      props.push prop

  # map over that array, get representations of property values and wrap them
  # with object carrying also property-specific information (name, required, ...)
  async.map props, (prop, next) ->
    handleValue prop, symbolTable, options, (err, propRepr) ->
      next err,
        name: prop.content.name.literal
        repr: propRepr
        required: 'required' in (prop.content?.valueDefinition?.typeDefinition?.attributes or [])

  , (err, reprWrappers) ->
    if err then return cb err

    # prepare containers for the final representation of the object
    propsRepr = {}
    requiredRepr = []

    # unwrap info for each property and render what needs to be rendered
    for {name, repr, required} in reprWrappers
      propsRepr[name] = repr
      if required
        requiredRepr.push name

    # build the final object representation and send it to callback
    repr =
      type: 'object'
      properties: propsRepr
    if requiredRepr.length > 0 then repr.required = requiredRepr
    cb null, repr


transform = (type, symbolTable, options, cb) ->
  handleObject type, symbolTable, options, (err, repr) ->
    if err then return cb err
    repr["$schema"] = "http://json-schema.org/draft-04/schema#"
    cb null, repr


module.exports = {
  transform
}
