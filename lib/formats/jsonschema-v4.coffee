
async = require 'async'
inspect = require '../inspect'
{resolveType} = require '../typeresolution'


# Takes literal and MSON type and provides JSON Schema value in corresponding type.
coerceLiteral = (literal, typeName, cb) ->
  switch typeName
    when 'string'
      return cb null, literal
    when 'number'
      return cb new Error "Literal '#{literal}' is not a number." if isNaN literal
      return cb null, parseFloat literal
    when 'boolean'
      return cb new Error "Literal '#{literal}' is not 'true' or 'false'." if literal not in ['true', 'false']
      return cb null, literal is 'true'
    else
      return cb new Error "Literal '#{literal}' can't have type '#{typeName}'."


# Turns multiple member nodes into 'resolved members', i.e. objects
# carrying both representations of those members in JSON Schema
# and also additional info, such as property names, attributes, etc.
resolveMembers = (members, resolveMember, inherited, cb) ->
  async.map members, (member, next) ->
    resolveMember member, inherited, next
  , cb


# Turns property node into a 'resolved property' object with both
# representation in JSON Schema and also additional info, such as property
# name, attributes, etc.
resolveProperty = (prop, inherited, cb) ->
  async.waterfall [
    (next) -> handleTypeNode prop, inherited, next
    (schema, next) ->
      next null,
        name: prop.name.literal
        schema: schema
        required: inspect.isRequired prop
        fixed: inspect.isFixed prop
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
    fixed
  } = context

  schema = type: 'object'
  schema.additionalProperties = false if fixed

  if resolvedProps.length
    async.parallel
      propsSchema: (next) -> buildSchemaForProperties resolvedProps, next
      reqSchema: (next) -> buildSchemaForRequired resolvedProps, next
    , (err, {propsSchema, reqSchema}) ->
      schema.properties = propsSchema
      schema.required = reqSchema if reqSchema?.length
      cb null, schema
  else
    cb null, schema


# Generates JSON Schema representation for given object type node.
handleObjectNode = (objectNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed objectNode
  props = inspect.listPropertyNodes objectNode

  async.waterfall [
    (next) -> resolveMembers props, resolveProperty, {fixed}, next
    (resolvedProps, next) ->
      buildObjectSchema {
        objectNode
        resolvedType
        fixed
        props
        resolvedProps
      }, next
  ], cb


# Turns value node into a 'resolved item' object with both
# representation in JSON Schema and also possible additional info.
resolveItem = (val, inherited, cb) ->
  async.waterfall [
    (next) -> handleTypeNode val, inherited, next
    (schema, next) ->
      next null,
        schema: schema
        fixed: inspect.isFixed val
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


buildSchemaForTupleItems = (arrayNode, resolvedItems, resolvedType, cb) ->
  # ordinary arrays
  return cb null, (ri.schema for ri in resolvedItems) if resolvedItems.length

  # inline arrays
  return cb new Error "Multiple nested types for fixed array." if resolvedType.nested.length > 1
  nestedTypeName = resolvedType.nested[0]

  vals = inspect.listValues arrayNode
  async.map vals, (val, next) ->
    buildSchemaForValue val, nestedTypeName, next
  , cb


buildSchemaForFixedItems = (resolvedItems, cb) ->
  schemas = (ri.schema for ri in resolvedItems when ri.fixed)

  if schemas.length isnt resolvedItems.length
    return cb new Error "Array can't contain fixed items alongside with non-fixed ones."

  return cb null, schemas[0] if schemas.length is 1
  cb null, anyOf: schemas


buildSchemaForItems = (context, cb) ->
  {
    arrayNode
    resolvedItems
    resolvedType
    fixed
  } = context

  # choosing strategy
  if fixed
    buildSchemaForTupleItems arrayNode, resolvedItems, resolvedType, cb
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
handleArrayNode = (arrayNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed arrayNode
  items = inspect.listItemNodes arrayNode

  heritage =
    fixed: fixed
    typeName: resolvedType.nested?[0]

  async.waterfall [
    (next) -> resolveMembers items, resolveItem, heritage, next
    (resolvedItems, next) ->
      buildArraySchema {
        arrayNode
        resolvedType
        fixed
        items
        resolvedItems
      }, next
  ], cb


# Generates JSON Schema representation for given primitive
# type node (string, number, etc.).
handlePrimitiveNode = (primitiveNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed primitiveNode

  if fixed
    vals = inspect.listValues primitiveNode, true
    if vals.length
      return cb new Error "Primitive type can't have multiple values." if vals.length > 1
      return buildSchemaForValue vals[0], resolvedType.name, cb

  cb null, type: resolvedType.name


# Generates JSON Schema representation for given type node.
handleTypeNode = (typeNode, inherited, cb) ->
  resolveType typeNode, inherited.typeName, (err, resolvedType) ->
    return cb err if err

    switch resolvedType.name
      when 'object'
        handleObjectNode typeNode, resolvedType, inherited, cb
      when 'array'
        handleArrayNode typeNode, resolvedType, inherited, cb
      else
        handlePrimitiveNode typeNode, resolvedType, inherited, cb


# Adds JSON Schema declaration to given schema object.
addSchemaDeclaration = (schema, cb) ->
  schema["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, schema


# Transforms given MSON AST into JSON Schema.
transform = (ast, cb) ->
  async.waterfall [
    (next) -> handleTypeNode ast, {}, next
    addSchemaDeclaration
  ], cb


module.exports = {
  transform
}
