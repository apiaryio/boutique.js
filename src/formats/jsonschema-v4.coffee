# JSON Schema format


async = require 'async'
inspect = require '../inspect'
{resolveType, resolveTypes} = require '../typeresolution'
{coerceLiteral, coerceNestedLiteral} = require '../jsonutils'


# Coerces multiple literals to JSON Schema values in given type.
coerceLiterals = (literals, typeName, cb) ->
  async.mapSeries literals, (literal, next) ->
    coerceLiteral literal, typeName, next
  , cb


# Adds description to given representation.
addDescription = (element, repr, cb) ->
  desc = inspect.findDescription element
  repr.description = desc if desc
  cb null, repr


# Adds default to given representation.
addDefault = (element, resolvedType, repr, cb) ->
  val = inspect.findDefault element
  return cb null, repr unless val

  coerceNestedLiteral val.literal, resolvedType.nested, (err, defaultValue) ->
    repr.default = defaultValue unless err
    cb err, repr


# Turns *Element* node containing object property into a 'resolved property'
# object with both representation in JSON Schema and optionally also
# some additional info.
resolveProperty = (prop, inherited, cb) ->
  handleElement prop, inherited, (err, repr) ->
    return cb err if err

    cb null,
      name: inspect.findPropertyName prop
      variableName: inspect.hasVariablePropertyName prop
      repr: repr
      required: inspect.isRequired prop, inherited

# Turns multiple *Element* nodes containing object properties into
# 'resolved property' objects with both representation in JSON Schema
# and optionally also some additional info.
resolveProperties = (props, inherited, cb) ->
  async.mapSeries props, (prop, next) ->
    resolveProperty prop, inherited, next
  , cb


# Groups resolved properties, e.g. according to the fact
# whether their name is variable or not.
groupResolvedProperties = (resolvedProps, cb) ->
  groups =
    regularProps: []
    variableProps: []
    requiredProps: []

  for resolvedProp in resolvedProps
    if resolvedProp.required
      groups.requiredProps.push resolvedProp
    if resolvedProp.variableName
      groups.variableProps.push resolvedProp
    else
      groups.regularProps.push resolvedProp

  cb null, groups


# Takes 'resolved properties' and generates JSON Schema for their wrapper
# object *Element* node.
buildObjectRepr = ({resolvedProps, fixed}, cb) ->
  repr = type: 'object'
  repr.additionalProperties = false if fixed

  if resolvedProps.length
    groupResolvedProperties resolvedProps, (err, allProps) ->
      return cb err if err

      {regularProps, variableProps, requiredProps} = allProps

      if regularProps.length
        propsRepr = {}
        propsRepr[rp.name] = rp.repr for rp in regularProps
        repr.properties = propsRepr

      if variableProps.length is 1
        repr.patternProperties = {'': variableProps[0].repr}

      else if variableProps.length > 1
        repr.patternProperties = {'': {}}

      if requiredProps.length
        repr.required = (rp.name for rp in requiredProps)

      cb null, repr
  else
    cb null, repr


# Generates JSON Schema representation for given *Element* node containing
# an object type.
handleObjectElement = (objectElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed objectElement, inherited
  heritage = inspect.getHeritage fixed
  props = inspect.listProperties objectElement

  resolveProperties props, heritage, (err, resolvedProps) ->
    return cb err if err

    buildObjectRepr {resolvedProps, fixed}, cb


# Turns *Element* node containing array or enum item into a 'resolved item'
# object with both representation in JSON Schema and optionally also
# some additional info.
resolveItem = (item, inherited, cb) ->
  handleElement item, inherited, (err, repr) ->
    return cb err if err
    cb null,
      repr: repr
      fixed: inspect.isFixed item


# Turns multiple *Element* nodes containing array or enum item into
# 'resolved item' objects with both representation in JSON Schema and
# optionally also some additional info.
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
  return cb null, type: resolvedType.name if inspect.isSample arrayElement

  fixed = inspect.isOrInheritsFixed arrayElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType
  items = inspect.listItems arrayElement

  resolveItems items, heritage, (err, resolvedItems) ->
    return cb err if err

    buildArrayRepr {arrayElement, resolvedItems, resolvedType, fixed}, cb


# Builds JSON Schema representation for a group of items with primitive types
# within enum *Element* node. Implements 'values' rendering strategy.
buildEnumValuesRepr = (group, inline, cb) ->
  typeName = group.typeName
  if inline
    literals = (val.literal for val in group.values)
  else
    literals = (inspect.listValues(item)[0].literal for item in group.items)

  coerceLiterals literals, typeName, (err, reprs) ->
    return cb err if err
    repr = type: typeName
    repr.enum = reprs if reprs.length
    cb null, repr


# Builds JSON Schema representation for a group of items with primitive types
# within enum *Element* node. Implements 'singleType' rendering strategy.
buildEnumAsSingleTypeRepr = (group, cb) ->
  cb null, type: group.typeName


# Builds JSON Schema representation for a group of items with primitive types
# within enum *Element* node.
buildEnumGroupRepr = (group, inherited, inline, cb) ->
  switch group.strategy
    when 'types'
      buildEnumTypesRepr group, inherited, cb
    when 'singleType'
      buildEnumAsSingleTypeRepr group, cb
    else
      buildEnumValuesRepr group, inline, cb


# Builds JSON Schema representation for *Element* node containing an enum.
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

    reprs = reprs.concat groupsReprs
    repr = if reprs.length > 1 then anyOf: reprs else reprs?[0] or {}
    cb null, repr


# Helper function to group item *Element* nodes by their primitive types.
# Provides also a separate array of items with non-primitive types.
groupItemsByPrimitiveTypes = (items, resolvedTypes, cb) ->
  primitiveItems = {}
  nonPrimitiveItems = []

  for item, i in items
    typeName = resolvedTypes[i].name

    if inspect.isPrimitive typeName
      primitiveItems[typeName] ?= []
      primitiveItems[typeName].push item
    else
      nonPrimitiveItems.push item

  groups = ({typeName, items, values: [], strategy: null} for own typeName, items of primitiveItems)
  cb null, groups, nonPrimitiveItems


# Helper function to inspect inline enum *Element* nodes. Groups items by their
# primitive type and gets information about how to render these groups.
inspectEnumItems = (items, nestedTypeName, cb) ->
  resolveTypes items, nestedTypeName, (err, resolvedTypes) ->
    return cb err if err

    groupItemsByPrimitiveTypes items, resolvedTypes, (err, groups, nonPrimitiveItems) ->
      return cb err if err

      for group in groups
        hasSamples = inspect.haveVariableValues group.items
        group.strategy = if hasSamples then 'singleType' else 'values'

      cb null, {inline: false, groups, nonPrimitiveItems}


# Helper function to inspect inline enum *Element* nodes. Creates one mostly
# artificial group object with almost only the values field populated.
inspectEnumInline = (enumElement, nestedTypeName, cb) ->
  if inspect.hasVariableValues enumElement
    values = []
    strategy = 'singleType'
  else
    values = inspect.listValues enumElement
    strategy = 'values'

  group = {typeName: nestedTypeName, items: [], values, strategy}
  cb null, {inline: true, nonPrimitiveItems: [], groups: [group]}


# Inspects given *Element* node containing an enum type. Provides a following
# object of various findings:
#
# - inline (boolean) - whether given enum is 'inline' or not
# - groups (array[Group]) - item elements containing primitive types only, grouped by those types
# - nonPrimitiveItems (array) - item elements containing non-primitive types only
#
# Group object looks like this:
#
# - typeName (string) - type name of item elements in the group
# - items (array) - item elements in the group
# - values (array) - value objects of the (inline) parent enum element
# - strategy: singleType, values (enum) - a strategy to follow when rendering representation of the group
#
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
  return cb null, {} if inspect.isSample enumElement

  fixed = inspect.isOrInheritsFixed enumElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType

  inspectEnum enumElement, resolvedType, (err, context) ->
    return cb err if err

    context.inherited = heritage
    buildEnumRepr context, cb


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
  resolveType element, inherited.typeName, (err, resolvedType) ->
    return cb err if err

    handle = createElementHandler resolvedType

    handle element, resolvedType, inherited, (err, repr) ->
      return cb err if err

      addDescription element, repr, (err, repr) ->
        return cb err if err

        addDefault element, resolvedType, repr, cb


# Adds JSON Schema declaration to given representation object.
addSchemaDeclaration = (repr, cb) ->
  repr["$schema"] = "http://json-schema.org/draft-04/schema#"
  cb null, repr


# Transforms given MSON AST into JSON Schema.
transform = (ast, cb) ->
  handleElement inspect.getAsElement(ast), {}, (err, repr) ->
    return cb err if err

    addSchemaDeclaration repr, cb


module.exports = {
  transform
}
