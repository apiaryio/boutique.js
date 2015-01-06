
async = require 'async'
inspect = require '../inspect'
{resolveType} = require '../typeresolution'


# Takes literal and MSON type and provides JSON value in corresponding type.
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
# carrying both representations of those members in JSON
# and also additional info, such as property names, attributes, etc.
resolveMembers = (members, resolveMember, inherited, cb) ->
  async.map members, (member, next) ->
    resolveMember member, inherited, next
  , cb


# Turns property node into a 'resolved property' object with both
# representation in JSON and also additional info, such as property
# name, attributes, etc.
resolveProperty = (prop, inherited, cb) ->
  async.waterfall [
    (next) -> handleTypeNode prop, inherited, next
    (repr, next) ->
      next null,
        name: prop.name.literal
        repr: repr
        fixed: inspect.isFixed prop
  ], cb


buildObjectRepr = ({resolvedProps}, cb) ->
  repr = {}
  for resolvedProp in resolvedProps
    repr[resolvedProp.name] = resolvedProp.repr
  cb null, repr


# Generates JSON representation for given object type node.
handleObjectNode = (objectNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed objectNode
  props = inspect.listPropertyNodes objectNode

  async.waterfall [
    (next) -> resolveMembers props, resolveProperty, {fixed}, next
    (resolvedProps, next) ->
      buildObjectRepr {
        objectNode
        resolvedType
        fixed
        props
        resolvedProps
      }, next
  ], cb


# Turns value node into a 'resolved item' object with both
# representation in JSON and also possible additional info.
resolveItem = (val, inherited, cb) ->
  async.waterfall [
    (next) -> handleTypeNode val, inherited, next
    (repr, next) ->
      next null,
        repr: repr
        fixed: inspect.isFixed val
  ], cb


buildReprForTupleItems = (arrayNode, resolvedItems, resolvedType, cb) ->
  # ordinary arrays
  return cb null, (ri.repr for ri in resolvedItems) if resolvedItems.length

  # inline arrays
  return cb new Error "Multiple nested types for fixed array." if resolvedType.nested.length > 1
  nestedTypeName = resolvedType.nested[0]

  vals = inspect.listValues arrayNode
  async.map vals, (val, next) ->
    coerceLiteral val.literal, nestedTypeName, next
  , cb


buildReprForItems = (resolvedItems, cb) ->
  cb null, (ri.repr for ri in resolvedItems)


# Takes 'resolved values' and generates JSON
# for their wrapper array type node.
buildArrayRepr = (context, cb) ->
  {
    arrayNode
    resolvedItems
    resolvedType
    fixed
  } = context

  # choosing strategy
  if fixed
    buildReprForTupleItems arrayNode, resolvedItems, resolvedType, cb
  else
    buildReprForItems resolvedItems, cb


# Generates JSON representation for given array type node.
handleArrayNode = (arrayNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed arrayNode
  items = inspect.listItemNodes arrayNode

  heritage =
    fixed: fixed
    typeName: resolvedType.nested?[0]

  async.waterfall [
    (next) -> resolveMembers items, resolveItem, heritage, next
    (resolvedItems, next) ->
      buildArrayRepr {
        arrayNode
        resolvedType
        fixed
        items
        resolvedItems
      }, next
  ], cb


# Generates JSON representation for given primitive
# type node (string, number, etc.).
handlePrimitiveNode = (primitiveNode, resolvedType, inherited, cb) ->
  vals = inspect.listValues primitiveNode, true
  if vals.length
    return cb new Error "Primitive type can't have multiple values." if vals.length > 1
    return coerceLiteral vals[0].literal, resolvedType.name, cb
  cb null, null  # empty representation is null


# Generates JSON representation for given type node.
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


# Transforms given MSON AST into JSON.
transform = (ast, cb) ->
  handleTypeNode ast, {}, cb


module.exports = {
  transform
}
