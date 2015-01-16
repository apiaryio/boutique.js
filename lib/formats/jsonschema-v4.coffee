# JSON Schema format


async = require 'async'
inspect = require '../inspect'
{coerceLiteral} = require '../jsonutils'
{resolveType, resolveTypes} = require '../typeresolution'


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
  ], cb


resolveProperties = (objectElement, inherited, cb) ->
  props = inspect.listProperties objectElement
  async.mapSeries props, (prop, next) ->
    resolveProperty prop, inherited, next
  , cb


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

  async.waterfall [
    (next) -> resolveProperties objectElement, heritage, next
    (resolvedProps, next) -> buildObjectRepr {resolvedProps, fixed}, next
  ], cb


# Turns *Element* node containing array or enum item into a 'resolved item'
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


resolveItems = (element, inherited, cb) ->
  items = inspect.listItems element
  async.mapSeries items, (item, next) ->
    resolveItem item, inherited, next
  , cb


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
  async.mapSeries vals, (val, next) ->
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
buildArrayItemsRepr = ({arrayElement, resolvedItems, resolvedType, fixed}, cb) ->
  if fixed
    buildTupleItemsRepr arrayElement, resolvedItems, resolvedType, cb
  else if (ri for ri in resolvedItems when ri.fixed).length  # if contains fixed
    buildFixedItemsRepr resolvedItems, cb
  else
    cb()  # returned itemsRepr will be 'falsy'


# Takes 'resolved items' and generates JSON Schema for their wrapper array
# *Element* node.
buildArrayRepr = (context, cb) ->
  buildArrayItemsRepr context, (err, itemsRepr) ->
    return cb err if err

    repr = type: 'array'
    repr.items = itemsRepr if itemsRepr
    cb null, repr


# Generates JSON Schema representation for given *Element* node containing
# an array type.
handleArrayElement = (arrayElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed arrayElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType

  async.waterfall [
    (next) -> resolveItems arrayElement, heritage, next
    (resolvedItems, next) -> buildArrayRepr {arrayElement, resolvedItems, resolvedType, fixed}, next
  ], cb


inspectEnum = (enumElement, resolvedType, cb) ->
  return cb new Error "Multiple nested types for enum." if resolvedType.nested.length > 1
  nestedTypeName = resolvedType.nested?[0]

  items = inspect.listItems enumElement
  if items.length
    hasSamples = inspect.haveVariableValues items
    resolveTypes items, nestedTypeName, (err, resolvedTypes) ->
      return cb err if err

      if inspect.areIdenticalAndPrimitive (rt.name for rt in resolvedTypes)
        strategy = if hasSamples then 'singleType' else 'values'
      else
        strategy = 'types'
      nestedTypeName ?= resolvedTypes[0].name

      cb null, {inline: false, strategy, nestedTypeName}
  else
    hasSamples = inspect.hasVariableValues enumElement
    strategy = if hasSamples then 'singleType' else 'values'
    cb null, {inline: true, strategy, nestedTypeName}


# Generates JSON Schema representation for given *Element* node containing
# an enum type.
handleEnumElement = (enumElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed enumElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType

  inspectEnum enumElement, resolvedType, (err, {strategy, inline, nestedTypeName}) ->
    return cb err if err

    switch strategy
      when 'types'  # cannot be inline
        async.waterfall [
          (next) -> resolveItems enumElement, heritage, next
          (resolvedItems, next) -> next null, anyOf: (ri.repr for ri in resolvedItems)
        ], cb

      when 'singleType'
        cb null, type: nestedTypeName

      else  # strategy 'values'
        if inline
          vals = inspect.listValues enumElement
          async.waterfall [
            (next) ->
              async.mapSeries vals, (val, done) ->
                coerceLiteral val.literal, nestedTypeName, done
              , next
            (reprs, next) -> next null, type: nestedTypeName, enum: reprs
          ], cb
        else
          async.waterfall [
            (next) ->
              items = inspect.listItems enumElement
              async.mapSeries items, (item, done) ->
                val = inspect.listValues(item)[0]
                coerceLiteral val.literal, nestedTypeName, done
              , next
            (reprs, next) -> next null, type: nestedTypeName, enum: reprs
          ], cb


# Generates JSON Schema representation for given *Element* node containing
# a primitive type (string, number, etc.).
handlePrimitiveElement = (primitiveElement, resolvedType, inherited, cb) ->
  # special case: inside enum, primitive elements are treated as fixed
  insideEnum = inherited.parentTypeName is 'enum'
  fixed = insideEnum or inspect.isOrInheritsFixed primitiveElement, inherited

  if fixed
    vals = inspect.listValues primitiveElement, true
    if vals.length
      return cb new Error "Primitive type can't have multiple values." if vals.length > 1
      return buildValueRepr vals[0], resolvedType.name, cb
  cb null, type: resolvedType.name  # returning repr right away


# *Element* handler factory.
createElementHandler = (resolvedType) ->
  switch resolvedType.name
    when 'object'
      handleObjectElement
    when 'array'
      handleArrayElement
    when 'enum'
      handleEnumElement
    else
      handlePrimitiveElement


# Generates JSON Schema representation for given *Element* node.
handleElement = (element, inherited, cb) ->
  async.waterfall [
    (next) -> resolveType element, inherited.typeName, next
    (resolvedType, next) ->
      handle = createElementHandler resolvedType
      handle element, resolvedType, inherited, next
  ], cb


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
