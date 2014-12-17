
async = require 'async'
{resolveType} = require '../typeresolution'


listProperties = (objectType, cb) ->
  props = []
  for member in (objectType.sections or []) when member.type is 'member'
    for prop in member.content when prop.type is 'property'
      props.push prop
  cb null, props


resolveProperty = (prop, options, cb) ->
  async.waterfall [
    (next) -> handleType prop.content, options, next
    (schema, next) ->
      next null,
        name: prop.content.name.literal
        schema: schema
        required: 'required' in (prop.content?.valueDefinition?.typeDefinition?.attributes or [])
  ], cb


resolveProperties = (props, options, cb) ->
  async.map props, (prop, next) ->
    resolveProperty prop, options, next
  , cb


buildObjectSchema = (resolvedProps, options, cb) ->
  schemaProps = {}
  schemaRequired = []

  for {name, schema, required} in resolvedProps
    schemaProps[name] = schema
    schemaRequired.push name if required

  schema =
    type: 'object'
    properties: schemaProps
  schema.required = schemaRequired if schemaRequired.length > 0

  cb null, schema


handleObject = (objectType, simpleTypeSpec, options, cb) ->
  async.waterfall [
    (next) -> listProperties objectType, next
    (properties, next) -> resolveProperties properties, options, next
    (resolvedProps, next) -> buildObjectSchema resolvedProps, options, next
  ], cb


handleArray = (arrayType, simpleTypeSpec, options, cb) ->
  cb null, type: 'array'


handlePrimitiveType = (primitiveType, simpleTypeSpec, options, cb) ->
  cb null, type: simpleTypeSpec.name


handleType = (type, options, cb) ->
  resolveType type, (err, simpleTypeSpec) ->
    return cb err if err
    switch simpleTypeSpec.name
      when 'object'
        handleObject type, simpleTypeSpec, options, cb
      when 'array'
        handleArray type, simpleTypeSpec, options, cb
      else
        handlePrimitiveType type, simpleTypeSpec, options, cb


addSchemaDeclaration = (schema, cb) ->
  schema["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, schema


transform = (ast, options, cb) ->
  async.waterfall [
    (next) -> handleType ast, options, next
    addSchemaDeclaration
  ], cb


module.exports = {
  transform
}
