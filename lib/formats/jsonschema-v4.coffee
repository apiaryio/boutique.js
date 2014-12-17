
async = require 'async'
{resolveType} = require '../typeresolution'


# Takes object type node and lists its property nodes.
listProperties = (objectType, cb) ->
  props = []
  for member in (objectType.sections or []) when member.type is 'member'
    for prop in member.content when prop.type is 'property'
      props.push prop
  cb null, props


# Turns property node into a 'resolved property' object with both
# representation in JSON Schema and also additional info, such as property
# name, attributes, etc.
resolveProperty = (prop, options, cb) ->
  async.waterfall [
    (next) -> handleType prop.content, options, next
    (schema, next) ->
      next null,
        name: prop.content.name.literal
        schema: schema
        required: 'required' in (prop.content?.valueDefinition?.typeDefinition?.attributes or [])
  ], cb


# Turns multiple property nodes into 'resolved properties', i.e. objects
# carrying both representations of those properties in JSON Schema
# and also additional info, such as property names, attributes, etc.
resolveProperties = (props, options, cb) ->
  async.map props, (prop, next) ->
    resolveProperty prop, options, next
  , cb


# Takes 'resolved properties' and generates JSON Schema
# for their wrapper object type node.
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


# Generates JSON Schema representation for given object type node.
handleObject = (objectType, simpleTypeSpec, options, cb) ->
  async.waterfall [
    (next) -> listProperties objectType, next
    (properties, next) -> resolveProperties properties, options, next
    (resolvedProps, next) -> buildObjectSchema resolvedProps, options, next
  ], cb


# Generates JSON Schema representation for given array type node.
handleArray = (arrayType, simpleTypeSpec, options, cb) ->
  cb null, type: 'array'


# Generates JSON Schema representation for given primitive
# type node (string, number, etc.).
handlePrimitiveType = (primitiveType, simpleTypeSpec, options, cb) ->
  cb null, type: simpleTypeSpec.name


# Generates JSON Schema representation for given type node.
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


# Adds JSON Schema declaration to given schema object.
addSchemaDeclaration = (schema, cb) ->
  schema["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, schema


# Transforms given MSON AST into JSON Schema.
transform = (ast, options, cb) ->
  async.waterfall [
    (next) -> handleType ast, options, next
    addSchemaDeclaration
  ], cb


module.exports = {
  transform
}
