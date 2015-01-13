# JSON format


async = require 'async'
inspect = require '../inspect'
{detectSuccessful} = require '../utils'
{coerceLiteral} = require '../jsonutils'
{resolveType} = require '../typeresolution'


# Takes literal and MSON types and provides JSON value in
# the corresponding type, which is the first to be able to successfully
# perfom the coercion.
#
# This allows us to correctly coerce in situations like `array[number, string]`
# with items `hello, 1, 2, world`, where coercion to `number` throws errors,
# but coercion to `string` is perfectly valid result.
coerceNestedLiteral = (literal, typeNames, cb) ->
  detectSuccessful typeNames, (typeName, next) ->
    coerceLiteral literal, typeName, next
  , cb


# Turns property node into a 'resolved property' object with both
# representation in JSON and also additional info, such as property
# name, attributes, etc.
resolveProperty = (prop, inherited, cb) ->
  async.waterfall [
    (next) -> handleElement prop, inherited, next
    (repr, next) ->
      next null,
        name: inspect.findPropertyName prop
        repr: repr
  ], cb


resolveOneOf = (oneof, inherited, cb) ->
  element = oneof.content[0]
  if element.class is 'group'
    resolveOneOfGroup element, inherited, cb
  else
    resolveProperty element, inherited, (err, resolvedProp) ->
      cb err, ([resolvedProp] unless err)


resolveOneOfGroup = (group, inherited, cb) ->
  async.mapSeries group.content, (prop, next) ->
    resolveProperty prop, inherited, next
  , cb


resolveProperties = (props, inherited, cb) ->
  results = []
  async.eachSeries props, (prop, next) ->
    if prop.class is 'oneOf'
      # oneOf can result in multiple properties
      resolveOneOf prop, inherited, (err, resolvedProps) ->
        Array::push.apply results, resolvedProps
        next err
    else
      resolveProperty prop, inherited, (err, resolvedProp) ->
        results.push resolvedProp
        next err
  , (err) ->
    cb err, results


buildObjectRepr = ({resolvedProps}, cb) ->
  repr = {}
  repr[rp.name] = rp.repr for rp in resolvedProps
  cb null, repr


# Generates JSON representation for given object element.
handleObjectElement = (objectElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed objectElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType
  props = inspect.listProperties objectElement

  async.waterfall [
    (next) -> resolveProperties props, heritage, next
    (resolvedProps, next) -> buildObjectRepr {resolvedProps}, next
  ], cb


# Turns value node into a 'resolved item' object with both
# representation in JSON and also possible additional info.
resolveItem = (item, inherited, cb) ->
  async.waterfall [
    (next) -> handleElement item, inherited, next
    (repr, next) -> next null, {repr}  # no additional info needed in this case
  ], cb


# Turns a list of array value nodes into an array of 'resolved item' objects
# with both representation in JSON and also possible additional info.
resolveArrayItems = (items, multipleInherited, cb) ->
  if multipleInherited.length is 1
    # single nested type definition, e.g. array[number]
    inherited = multipleInherited[0]
    async.mapSeries items, (item, next) ->
      resolveItem item, inherited, next
    , cb
  else
    # multiple nested type definitions, e.g. array[number,string]
    async.mapSeries items, (item, next) ->
      # we iterate over types and render the first one, which can be
      # successfully applied to given value (e.g. for array[number,string],
      # if coercing to `number` fails, this algorithm skips it and tries
      # to coerce with `string`).
      detectSuccessful multipleInherited, (inherited, done) ->
        resolveItem item, inherited, done
      , next
    , cb


# Takes 'resolved values' and generates JSON
# for their wrapper array element.
buildArrayRepr = (context, cb) ->
  {
    arrayElement
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
  vals = inspect.listValues arrayElement
  async.mapSeries vals, (val, next) ->
    coerceNestedLiteral val.literal, resolvedType.nested, next
  , cb


# Generates JSON representation for given array element.
handleArrayElement = (arrayElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed arrayElement, inherited
  heritages = inspect.listPossibleHeritages fixed, resolvedType
  items = inspect.listItems arrayElement

  async.waterfall [
    (next) -> resolveArrayItems items, heritages, next
    (resolvedItems, next) ->
      buildArrayRepr {
        arrayElement
        resolvedItems
        resolvedType
        fixed
      }, next
  ], cb


resolveEnumItems = (items, inherited, cb) ->
  item = items?[0]
  return cb null, null unless item  # "falsy" resolvedItem
  resolveItem item, inherited, cb


# Takes 'resolved values' and generates JSON
# for their wrapper enum element.
buildEnumRepr = (context, cb) ->
  {
    enumElement
    resolvedItem
    resolvedType
  } = context

  # ordinary enums
  return cb null, resolvedItem.repr if resolvedItem

  # inline enums
  return cb new Error "Multiple nested types for enum." if resolvedType.nested.length > 1
  vals = inspect.listValues enumElement
  if vals.length
    coerceLiteral vals[0].literal, resolvedType.nested[0], cb
  else
    cb null, null  # empty representation is null


# Generates JSON representation for given enum element.
handleEnumElement = (enumElement, resolvedType, inherited, cb) ->
  fixed = inspect.isOrInheritsFixed enumElement, inherited
  heritage = inspect.getHeritage fixed, resolvedType
  items = inspect.listItems enumElement

  async.waterfall [
    (next) -> resolveEnumItems items, heritage, next
    (resolvedItem, next) ->
      buildEnumRepr {
        enumElement
        resolvedItem
        resolvedType
      }, next
  ], cb


# Generates JSON representation for given primitive
# element (string, number, etc.).
handlePrimitiveElement = (primitiveElement, resolvedType, inherited, cb) ->
  vals = inspect.listValues primitiveElement
  if vals.length
    return cb new Error "Primitive type can't have multiple values." if vals.length > 1
    return coerceLiteral vals[0].literal, resolvedType.name, cb
  cb null, null  # empty representation is null


# Generates JSON representation for given element.
handleElement = (element, inherited, cb) ->
  resolveType element, inherited.typeName, (err, resolvedType) ->
    return cb err if err

    switch resolvedType.name
      when 'object'
        handleObjectElement element, resolvedType, inherited, cb
      when 'array'
        handleArrayElement element, resolvedType, inherited, cb
      when 'enum'
        handleEnumElement element, resolvedType, inherited, cb
      else
        handlePrimitiveElement element, resolvedType, inherited, cb


# Transforms given MSON AST into JSON.
transform = (ast, cb) ->
  handleElement inspect.getAsElement(ast), {}, cb


module.exports = {
  transform
}
