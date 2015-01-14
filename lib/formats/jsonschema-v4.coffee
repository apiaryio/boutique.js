# JSON Schema format


async = require 'async'
inspect = require '../inspect'
{coerceLiteral} = require '../jsonutils'
{resolveType} = require '../typeresolution'


# Turns multiple *Element* nodes into 'resolved elements', i.e. objects
# carrying both representation in JSON Schema and optionally also
# some additional info.
#
# The implementation of such resolution is to be provided in the
# *resolveElement* argument in form of an asynchronous function with
# following signature:
#
#     (element, inherited, cb) -> ...
#
resolveElements = (elements, resolveElement, inherited, cb) ->
  async.map elements, (element, next) ->
    resolveElement element, inherited, next
  , cb


# Turns *Element* node containing object property into a 'resolved property'
# object with both representation in JSON Schema and optionally also
# some additional info.
resolveProperty = (prop, inherited, cb) ->
  async.waterfall [
    (next) -> handleElement prop, inherited, next
    (repr, next) ->
      next null,
        name: inspect.findPropertyName prop, false
        repr: repr
        required: inspect.isRequired prop
        fixed: inspect.isFixed prop
  ], cb


# Takes 'resolved properties' and generates JSON Schema
# for `properties` keyword.
buildPropertiesRepr = (resolvedProps, cb) ->
  repr = {}
  repr[rp.name] = rp.repr for rp in resolvedProps
  cb null, repr


# Takes 'resolved properties' and generates JSON Schema
# for `required` keyword.
buildRequiredRepr = (resolvedProps, cb) ->
  cb null, (rp.name for rp in resolvedProps when rp.required)


# Takes 'resolved properties' and generates JSON Schema for their wrapper
# object *Element* node.
buildObjectRepr = ({resolvedProps, fixed}, cb) ->
  repr = type: 'object'
  repr.additionalProperties = false if fixed

  if resolvedProps.length
    async.parallel
      propsRepr: (next) -> buildPropertiesRepr resolvedProps, next
      reqRepr: (next) -> buildRequiredRepr resolvedProps, next
    , (err, {propsRepr, reqRepr}) ->
      repr.properties = propsRepr
      repr.required = reqRepr if reqRepr?.length
      cb null, repr
  else
    cb null, repr


# Generates JSON Schema representation for given *Element* node containing
# an object type.
handleObjectElement = (objectElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed objectElement, inherited
  heritage = inspect.getHeritage fixed
  props = inspect.listProperties objectElement

  async.waterfall [
    (next) -> resolveElements props, resolveProperty, heritage, next
    (resolvedProps, next) -> buildObjectRepr {resolvedProps, fixed}, next
  ], cb


# Turns *Element* node containing array item into a 'resolved item'
# object with both representation in JSON and optionally also
# some additional info.
resolveItem = (item, inherited, cb) ->
  async.waterfall [
    (next) -> handleElement item, inherited, next
    (repr, next) ->
      next null,
        repr: repr
        fixed: inspect.isFixed item
  ], cb


# Takes *Symbol* node for value and generates JSON Schema requiring the value
# to be present in the validated document.
buildValueRepr = (val, typeName, cb) ->
  repr = type: typeName

  if val.variable
    cb null, repr
  else
    coerceLiteral val.literal, typeName, (err, coercedVal) ->
      return cb err if err
      repr.enum = [coercedVal]
      cb null, repr


# Takes 'resolved items' and generates JSON Schema for their wrapper array
# *Element* node. This function works exclusively with fixed arrays (tuples).
buildTupleItemsRepr = (arrayElement, resolvedItems, resolvedType, cb) ->
  # ordinary arrays
  return cb null, (ri.repr for ri in resolvedItems) if resolvedItems.length

  # inline arrays
  return cb new Error "Multiple nested types for fixed array." if resolvedType.nested.length > 1
  nestedTypeName = resolvedType.nested[0]

  vals = inspect.listValues arrayElement
  async.map vals, (val, next) ->
    buildValueRepr val, nestedTypeName, next
  , cb


# Takes 'resolved items' and generates JSON Schema for their wrapper array
# *Element* node. This function works exclusively with NOT fixed arrays
# containing fixed elements (meaning: *this array can contain any number
# of those types, but only those types*).
buildFixedItemsRepr = (resolvedItems, cb) ->
  reprs = (ri.repr for ri in resolvedItems when ri.fixed)

  if reprs.length isnt resolvedItems.length
    return cb new Error "Array can't contain fixed items alongside with non-fixed ones."

  return cb null, reprs[0] if reprs.length is 1
  cb null, anyOf: reprs


# Takes 'resolved items' and generates JSON Schema for their wrapper array
# *Element* node. This function chooses strategy and delegates to other
# helper functions.
buildItemsRepr = ({arrayElement, resolvedItems, resolvedType, fixed}, cb) ->
  if fixed
    buildTupleItemsRepr arrayElement, resolvedItems, resolvedType, cb
  else if (ri for ri in resolvedItems when ri.fixed).length  # if contains fixed
    buildFixedItemsRepr resolvedItems, cb
  else
    cb()  # returned itemsRepr will be 'falsy'


# Takes 'resolved items' and generates JSON Schema for their wrapper array
# *Element* node.
buildArrayRepr = (context, cb) ->
  buildItemsRepr context, (err, itemsRepr) ->
    return cb err if err

    repr = type: 'array'
    repr.items = itemsRepr if itemsRepr
    cb null, repr


# Generates JSON Schema representation for given *Element* node containing
# an array type.
handleArrayElement = (arrayElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed arrayElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType
  items = inspect.listItems arrayElement

  async.waterfall [
    (next) -> resolveElements items, resolveItem, heritage, next
    (resolvedItems, next) -> buildArrayRepr {arrayElement, resolvedItems, resolvedType, fixed}, next
  ], cb


# Generates JSON Schema representation for given *Element* node containing
# a primitive type (string, number, etc.).
handlePrimitiveElement = (primitiveElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed primitiveElement, inherited
  if fixed
    vals = inspect.listValues primitiveElement, true
    if vals.length
      return cb new Error "Primitive type can't have multiple values." if vals.length > 1
      return buildValueRepr vals[0], resolvedType.name, cb
  cb null, type: resolvedType.name  # returning repr right away


# Generates JSON Schema representation for given *Element* node.
handleElement = (element, inherited, cb) ->
  resolveType element, inherited.typeName, (err, resolvedType) ->
    return cb err if err

    switch resolvedType.name
      when 'object'
        handleObjectElement element, resolvedType, inherited, cb
      when 'array'
        handleArrayElement element, resolvedType, inherited, cb
      else
        handlePrimitiveElement element, resolvedType, inherited, cb


# Adds JSON Schema declaration to given representation object.
addSchemaDeclaration = (repr, cb) ->
  repr["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, repr


# Transforms given MSON AST into JSON Schema.
transform = (ast, cb) ->
  async.waterfall [
    (next) -> handleElement inspect.getAsElement(ast), {}, next
    addSchemaDeclaration
  ], cb


module.exports = {
  transform
}
