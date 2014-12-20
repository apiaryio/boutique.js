
async = require 'async'
inspect = require '../inspect'
{resolveType} = require '../typeresolution'


# TODO should be tested properly
#
# Takes value and MSON type and provides JSON Schema value in corresponding type.
coerceValue = (value, typeName, cb) ->
  switch typeName
    when 'string'
      return cb null, value
    when 'number'
      return cb new Error "Value '#{value}' is not a number." if isNaN value
      return cb null, parseFloat value
    when 'boolean'
      return cb new Error "Value '#{value}' is not 'true' or 'false'." if value not in ['true', 'false']
      return cb null, value is 'true'
    else
      return cb new Error "Value '#{value}' can't have type '#{typeName}'."


# Turns property node into a 'resolved property' object with both
# representation in JSON Schema and also additional info, such as property
# name, attributes, etc.
resolveProperty = (prop, inheritsFixed, options, cb) ->
  async.waterfall [
    (next) -> handleType prop.content, inheritsFixed, options, next
    (schema, next) ->
      next null,
        name: prop.content.name.literal
        schema: schema
        required: inspect.isRequired prop.content
  ], cb


# Turns multiple property nodes into 'resolved properties', i.e. objects
# carrying both representations of those properties in JSON Schema
# and also additional info, such as property names, attributes, etc.
resolveProperties = (props, inheritsFixed, options, cb) ->
  async.map props, (prop, next) ->
    resolveProperty prop, inheritsFixed, options, next
  , cb


# Takes 'resolved properties' and generates JSON Schema
# for their wrapper object type node.
buildObjectSchema = (objectType, resolvedProps, isFixed, options, cb) ->
  schemaProps = {}
  schemaRequired = []

  for {name, schema, required} in resolvedProps
    schemaProps[name] = schema
    schemaRequired.push name if required

  schema =
    type: 'object'
    properties: schemaProps

  schema.additionalProperties = false if isFixed
  schema.required = schemaRequired if schemaRequired.length > 0

  cb null, schema


# Generates JSON Schema representation for given object type node.
handleObject = (objectType, resolvedType, inheritsFixed, options, cb) ->
  isFixed = inheritsFixed or inspect.isFixed objectType
  props = inspect.listPropertyTypes objectType
  async.waterfall [
    (next) -> resolveProperties props, isFixed, options, next
    (resolvedProps, next) -> buildObjectSchema objectType, resolvedProps, isFixed, options, next
  ], cb


# non-DRY / UGLY / WIP ALERT!
#
# Turns value node into a 'resolved value' object with both
# representation in JSON Schema and also possible additional info.
resolveValue = (val, inheritsFixed, options, cb) ->
  async.waterfall [
    (next) ->
      async.parallel
        resolvedType: (done) -> resolveType val, done
        schema: (done) -> handleType val.content, inheritsFixed, options, done
      , next
    ({resolvedType, schema}, next) ->
      next null,
        typeName: resolvedType.name
        schema: schema
  ], cb


# non-DRY / UGLY / WIP ALERT!
#
# Turns multiple property nodes into 'resolved values', i.e. objects
# carrying both representations of those values in JSON Schema
# and also possible additional info.
resolveValues = (vals, inheritsFixed, options, cb) ->
  async.map vals, (val, next) ->
    resolveValue val, inheritsFixed, options, next
  , cb


# non-DRY / UGLY / WIP ALERT!
#
# Takes 'resolved values' and generates JSON Schema
# for their wrapper array type node.
buildArraySchema = (arrayType, resolvedVals, resolvedType, isFixed, options, cb) ->
  schema = type: 'array'
  if inspect.isFixed arrayType
    schema.items = (rv.schema for rv in resolvedVals)
  cb null, schema


# non-DRY / UGLY / WIP ALERT!
#
# Generates JSON Schema representation for given array type node.
handleArray = (arrayType, resolvedType, inheritsFixed, options, cb) ->
  isFixed = inheritsFixed or inspect.isFixed arrayType
  vals = inspect.listValueTypes arrayType  # such a mess! https://github.com/apiaryio/mson-ast/pull/9#discussion_r22136108
  async.waterfall [
    (next) -> resolveValues vals, isFixed, options, next
    (resolvedVals, next) -> buildArraySchema arrayType, resolvedVals, resolvedType, isFixed, options, next
  ], cb


# non-DRY / UGLY / WIP ALERT!
#
# Generates JSON Schema representation for given primitive
# type node (string, number, etc.).
handlePrimitiveType = (primitiveType, resolvedType, inheritsFixed, options, cb) ->
  schema = type: resolvedType.name
  if inheritsFixed or inspect.isFixed primitiveType
    vals = inspect.listValues primitiveType  # such a mess! https://github.com/apiaryio/mson-ast/pull/9#discussion_r22136108
    if vals.length > 1
      return cb new Error "Primitive type can't have multiple values."
    else if vals.length > 0
      coerceValue vals[0].literal, resolvedType.name, (err, value) ->
        return cb err if err
        schema.enum = [value]
        cb null, schema
    else
      cb null, schema
  else
    cb null, schema


# Generates JSON Schema representation for given type node.
handleType = (type, inheritsFixed, options, cb) ->
  resolveType type, (err, resolvedType) ->
    return cb err if err
    switch resolvedType.name
      when 'object'
        handleObject type, resolvedType, inheritsFixed, options, cb
      when 'array'
        handleArray type, resolvedType, inheritsFixed, options, cb
      else
        handlePrimitiveType type, resolvedType, inheritsFixed, options, cb


# Adds JSON Schema declaration to given schema object.
addSchemaDeclaration = (schema, cb) ->
  schema["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, schema


# Transforms given MSON AST into JSON Schema.
transform = (ast, options, cb) ->
  async.waterfall [
    (next) -> handleType ast, false, options, next
    addSchemaDeclaration
  ], cb


module.exports = {
  transform
}
