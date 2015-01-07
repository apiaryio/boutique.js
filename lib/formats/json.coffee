
async = require 'async'
inspect = require '../inspect'
{resolveType} = require '../typeresolution'


detectSuccessful = (arr, fn, cb) ->
  # Here we're trying each item of given array and result of the first
  # one on which the given function doesn't produce error is taken as the
  # result of this whole function. If none of given items pass the function
  # without error, the error of the one which was tried as the last one
  # is passed.
  error = null
  result = null

  async.detectSeries arr, (item, next) ->
    fn item, (err, res) ->
      [error, result] = if err then [err, null] else [null, res]
      next not err
  , ->
    cb error, result


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


# Takes literal and MSON types and provides JSON value in
# the corresponding type, which is the first to be able to successfully
# perfom the coercion.
coerceNestedLiteral = (literal, typeNames, cb) ->
  # This allows to correctly coerce in situations like `array[number, string]`
  # with items `hello, 1, 2, world`, where coercion to `number` throws errors,
  # but coercion to `string` is perfectly valid result.
  detectSuccessful typeNames, (typeName, next) ->
    coerceLiteral literal, typeName, next
  , cb


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
        name: prop.name.literal or prop.name.variable?.values?[0].literal
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


# Takes 'resolved values' and generates JSON
# for their wrapper array type node.
buildArrayRepr = (context, cb) ->
  {
    arrayNode
    resolvedItems
    resolvedType
    fixed
  } = context

  # ordinary arrays
  if resolvedItems.length
    if fixed
      repr = (ri.repr for ri in resolvedItems)
    else
      repr = (ri.repr for ri in resolvedItems when ri.repr isnt null)
    return cb null, repr

  # inline arrays
  return cb new Error "Multiple nested types for fixed array." if fixed and resolvedType.nested.length > 1
  vals = inspect.listValues arrayNode
  async.map vals, (val, next) ->
    coerceNestedLiteral val.literal, resolvedType.nested, next
  , cb


# Generates JSON representation for given array type node.
handleArrayNode = (arrayNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed arrayNode
  items = inspect.listItemNodes arrayNode

  async.waterfall [
    (next) ->
      async.map items, (item, n) ->
        if resolvedType.nested.length > 1
          detectSuccessful resolvedType.nested, (typeName, done) ->
            resolveItem item, {fixed, typeName}, done
          , n
        else
          resolveItem item, {fixed, typeName: resolvedType.nested?[0]}, n
      , next
    (resolvedItems, next) ->
      buildArrayRepr {
        arrayNode
        resolvedType
        fixed
        items
        resolvedItems
      }, next
  ], cb


# Takes 'resolved values' and generates JSON
# for their wrapper enum type node.
buildEnumRepr = (context, cb) ->
  {
    enumNode
    resolvedItem
    resolvedType
    fixed
  } = context

  # ordinary enums
  if resolvedItem
    return cb null, resolvedItem.repr

  # inline enums
  return cb new Error "Multiple nested types for enum." if resolvedType.nested.length > 1
  vals = inspect.listValues enumNode
  if vals.length
    coerceLiteral vals[0].literal, resolvedType.nested?[0], cb
  else
    cb null, null


# Generates JSON representation for given enum type node.
handleEnumNode = (enumNode, resolvedType, inherited, cb) ->
  fixed = inherited.fixed or inspect.isFixed enumNode
  item = inspect.listItemNodes(enumNode)?[0]

  async.waterfall [
    (next) ->
      return next null, null unless item
      resolveItem item, {fixed, typeName: resolvedType.nested?[0]}, next
    (resolvedItem, next) ->
      buildEnumRepr {
        enumNode
        resolvedType
        fixed
        item
        resolvedItem
      }, next
  ], cb


# Generates JSON representation for given primitive
# type node (string, number, etc.).
handlePrimitiveNode = (primitiveNode, resolvedType, inherited, cb) ->
  vals = inspect.listValues primitiveNode
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
      when 'enum'
        handleEnumNode typeNode, resolvedType, inherited, cb
      else
        handlePrimitiveNode typeNode, resolvedType, inherited, cb


# Transforms given MSON AST into JSON.
transform = (ast, cb) ->
  handleTypeNode ast, {}, cb


module.exports = {
  transform
}
