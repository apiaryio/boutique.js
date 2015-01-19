# JSON Schema format


async = require 'async'
inspect = require '../inspect'
{coerceLiteral} = require '../jsonutils'
{resolveType, resolveTypes} = require '../typeresolution'


coerceLiterals = (literals, typeName, cb) ->
  async.mapSeries literals, (literal, next) ->
    coerceLiteral literal, typeName, next
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
  ], cb


resolveProperties = (props, inherited, cb) ->
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
  props = inspect.listProperties objectElement

  async.waterfall [
    (next) -> resolveProperties props, heritage, next
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


resolveItems = (items, inherited, cb) ->
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
  items = inspect.listItems arrayElement

  async.waterfall [
    (next) -> resolveItems items, heritage, next
    (resolvedItems, next) -> buildArrayRepr {arrayElement, resolvedItems, resolvedType, fixed}, next
  ], cb


buildEnumTypeRepr = (item, inherited, cb) ->
  async.waterfall [
    (next) ->
    (resolvedItem, next) -> next null, resolvedItem.repr
  ], cb


buildEnumValuesRepr = (group, inline, cb) ->
  typeName = group.typeName
  if inline
    literals = (val.literal for val in group.values)
  else
    literals = (inspect.listValues(item)[0].literal for item in group.items)

  coerceLiterals literals, typeName, (err, reprs) ->
    cb err, (type: typeName, enum: reprs unless err)


buildEnumAsSingleTypeRepr = (group, cb) ->
  cb null, type: group.typeName


buildEnumGroupRepr = (group, inherited, inline, cb) ->
  switch group.strategy
    when 'types'
      buildEnumTypesRepr group, inherited, cb
    when 'singleType'
      buildEnumAsSingleTypeRepr group, cb
    else
      buildEnumValuesRepr group, inline, cb


buildEnumRepr = ({groups, inherited, inline, nonPrimitiveItems}, cb) ->
  async.parallel
    groupsReprs: (next) ->
      async.map groups, (group, done) ->
        buildEnumGroupRepr group, inherited, inline, done
      , next
    reprs: (next) ->
      resolveItems nonPrimitiveItems, inherited, (err, resolvedItems) ->
        next err, ((ri.repr for ri in resolvedItems) unless err)
  , (err, {groupsReprs, reprs}) ->
    return cb err if err

    Array::push.apply reprs, groupsReprs
    repr = if reprs.length > 1 then anyOf: reprs else reprs?[0] or {}
    cb null, repr


groupItemsByPrimitiveTypes = (items, nestedTypeName, cb) ->
  async.waterfall [
    (next) -> resolveTypes items, nestedTypeName, next
    (resolvedTypes, next) ->
      primitiveItems = {}
      nonPrimitiveItems = []

      for item, i in items
        typeName = resolvedTypes[i].name

        if inspect.isPrimitive typeName
          primitiveItems[typeName] ?= []
          primitiveItems[typeName].push item
        else
          nonPrimitiveItems.push item

      groups = ({typeName, items} for own typeName, items of primitiveItems)
      next null, groups, nonPrimitiveItems
  ], cb


inspectEnumItems = (items, nestedTypeName, cb) ->
  async.waterfall [
    (next) -> groupItemsByPrimitiveTypes items, nestedTypeName, next
    (groups, nonPrimitiveItems, next) ->
      for group in groups
        hasSamples = inspect.haveVariableValues group.items
        group.strategy = if hasSamples then 'singleType' else 'values'
        group.values = []
      next null, {inline: false, groups, nonPrimitiveItems}
  ], cb


inspectEnumInline = (enumElement, nestedTypeName, cb) ->
  if inspect.hasVariableValues enumElement
    values = []
    strategy = 'singleType'
  else
    values = inspect.listValues enumElement
    strategy = 'values'

  group = {typeName: nestedTypeName, items: [], values, strategy}
  cb null, {inline: true, nonPrimitiveItems: [], groups: [group]}


inspectEnum = (enumElement, resolvedType, cb) ->
  return cb new Error "Multiple nested types for enum." if resolvedType.nested.length > 1
  nestedTypeName = resolvedType.nested?[0]

  items = inspect.listItems enumElement
  if items.length
    inspectEnumItems items, nestedTypeName, cb
  else
    inspectEnumInline enumElement, nestedTypeName, cb


# Generates JSON Schema representation for given *Element* node containing
# an enum type.
handleEnumElement = (enumElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed enumElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType

  async.waterfall [
    (next) -> inspectEnum enumElement, resolvedType, next
    (context, next) ->
      context.inherited = heritage
      buildEnumRepr context, next
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
