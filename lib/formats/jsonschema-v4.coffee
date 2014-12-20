
async = require 'async'
inspect = require '../inspect'
{resolveType} = require '../typeresolution'


# TODO should be tested properly
#
# Takes literal and MSON type and provides JSON Schema value in corresponding type.
coerceLiteral = (lit, typeName, cb) ->
  switch typeName
    when 'string'
      return cb null, lit
    when 'number'
      return cb new Error "Literal '#{lit}' is not a number." if isNaN lit
      return cb null, parseFloat lit
    when 'boolean'
      return cb new Error "Literal '#{lit}' is not 'true' or 'false'." if lit not in ['true', 'false']
      return cb null, lit is 'true'
    else
      return cb new Error "Literal '#{lit}' can't have type '#{typeName}'."


# Turns multiple member nodes into 'resolved members', i.e. objects
# carrying both representations of those members in JSON Schema
# and also additional info, such as property names, attributes, etc.
resolveMembers = (members, resolveMember, inheritsFixed, options, cb) ->
  async.map members, (member, next) ->
    resolveMember member, inheritsFixed, options, next
  , cb


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
        fixed: inspect.isFixed prop.content
  ], cb


buildSchemaForProperties = (resolvedProps, cb) ->
  schema = {}
  schema[rp.name] = rp.schema for rp in resolvedProps
  cb null, schema


buildSchemaForRequired = (resolvedProps, cb) ->
  cb null, (rp.name for rp in resolvedProps when rp.required)


buildObjectSchema = (context, cb) ->
  {
    resolvedProps
    isFixed

  } = context

  schema = type: 'object'
  schema.additionalProperties = false if isFixed

  if resolvedProps.length
    async.parallel
      propsSchema: (next) -> buildSchemaForProperties resolvedProps, next
      reqSchema: (next) -> buildSchemaForRequired resolvedProps, next
    , (err, {propsSchema, reqSchema}) ->
      schema.properties = propsSchema
      schema.required = reqSchema if reqSchema.length
      cb null, schema
  else
    cb null, schema


# Generates JSON Schema representation for given object type node.
handleObject = (objectType, resolvedType, inheritsFixed, options, cb) ->
  isFixed = inheritsFixed or inspect.isFixed objectType
  props = inspect.listPropertyTypes objectType

  async.waterfall [
    (next) -> resolveMembers props, resolveProperty, isFixed, options, next
    (resolvedProps, next) ->
      buildObjectSchema {

        objectType
        resolvedType
        isFixed
        props
        resolvedProps
        options

      }, next
  ], cb


# Turns value node into a 'resolved item' object with both
# representation in JSON Schema and also possible additional info.
resolveItem = (val, inheritsFixed, options, cb) ->
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
        fixed: inspect.isFixed val.content
  ], cb


buildSchemaForValue = (val, typeName, cb) ->
  schema = type: typeName

  if val.variable
    cb null, schema
  else
    coerceLiteral val.literal, typeName, (err, coercedVal) ->
      return cb err if err
      schema.enum = [coercedVal]
      cb null, schema


buildSchemaForTupleItems = (arrayType, resolvedItems, resolvedType, cb) ->
  # ordinary arrays
  return cb null, (ri.schema for ri in resolvedItems) if resolvedItems.length

  # inline arrays
  return cb new Error "Multiple nested types for fixed array." if resolvedType.nested.length > 1
  nestedType = resolvedType.nested[0]

  vals = inspect.listValues arrayType
  async.map vals, (val, next) ->
    buildSchemaForValue val, nestedType, next
  , cb


buildSchemaForFixedItems = (resolvedItems, cb) ->
  schemas = (ri.schema for ri in resolvedItems when ri.fixed)

  if schemas.length isnt resolvedItems.length
    return cb new Error "Array can't contain fixed items alongside with non-fixed ones."

  return cb null, schemas[0] if schemas.length is 1
  cb null, anyOf: schemas


buildSchemaForItems = (context, cb) ->
  {
    arrayType
    resolvedItems
    resolvedType
    isFixed

  } = context

  # choosing strategy
  if isFixed
    buildSchemaForTupleItems arrayType, resolvedItems, resolvedType, cb

  else if (ri for ri in resolvedItems when ri.fixed).length  # containsFixed
    buildSchemaForFixedItems resolvedItems, cb

  else
    cb()  # returned itemsSchema will be "falsy"


# Takes 'resolved values' and generates JSON Schema
# for their wrapper array type node.
buildArraySchema = (context, cb) ->
  buildSchemaForItems context, (err, itemsSchema) ->
    return cb err if err

    schema = type: 'array'
    schema.items = itemsSchema if itemsSchema

    cb null, schema


# Generates JSON Schema representation for given array type node.
handleArray = (arrayType, resolvedType, inheritsFixed, options, cb) ->
  isFixed = inheritsFixed or inspect.isFixed arrayType
  items = inspect.listItemTypes arrayType

  async.waterfall [
    (next) -> resolveMembers items, resolveItem, isFixed, options, next
    (resolvedItems, next) ->
      buildArraySchema {

        arrayType
        resolvedType
        isFixed
        items
        resolvedItems
        options

      }, next
  ], cb


# Generates JSON Schema representation for given primitive
# type node (string, number, etc.).
handlePrimitiveType = (primitiveType, resolvedType, inheritsFixed, options, cb) ->
  isFixed = inheritsFixed or inspect.isFixed primitiveType

  if isFixed
    vals = inspect.listValues primitiveType, true
    if vals.length
      return cb new Error "Primitive type can't have multiple values." if vals.length > 1
      return buildSchemaForValue vals[0], resolvedType.name, cb

  cb null, type: resolvedType.name


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
