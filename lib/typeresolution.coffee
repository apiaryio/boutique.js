# Resolves type name of given MSON AST type node object


async = require 'async'
inspect = require './inspect'


# Listing of all base types as defined in MSON AST spec.
baseTypes = ['boolean', 'string', 'number', 'array', 'enum', 'object']


# Calls given function with an error in case given type name is not one
# of base types.
ensureBaseType = (type, cb) ->
  if type not in baseTypes
    cb new Error "Unable to resolve type: #{type}"
  else
    cb null


# Provides nested types as array of type names
# for given *typeSpecification* object.
simplifyNestedTypes = (typeSpec, cb) ->
  return cb null, [] if (typeSpec?.nestedTypes?.length or 0) < 1  # no nested types
  name = inspect.findTypeName typeSpec

  # just playing safe, this should be already ensured by MSON parser
  if name not in ['array', 'enum']
    return cb new Error "Nested types are allowed only for array and enum types."

  nested = typeSpec.nestedTypes
  async.map nested, ensureBaseType, (err) ->
    return cb err if err  # non-base types result in error
    cb null, nested


# Turns *typeSpecification* object as described in
# https://github.com/apiaryio/mson-ast#type-definition into something simpler:
#
#     name: ...
#     nested: [...]
#
# In case it isn't able to resolve this *typeSpecification* object with
# base types only, ends with an error (Boutique builds no symbol table,
# so it can't resolve any possible inheritance).
simplifyTypeSpecification = (typeSpec, cb) ->
  name = inspect.findTypeName typeSpec
  return cb null, null if not name  # no type name? return null...

  async.waterfall [
    (next) -> ensureBaseType name, next
    (next) -> simplifyNestedTypes typeSpec, next
  ], (err, nested) ->
    cb err, ({name, nested} unless err)


# Helps to identify whether given *Element* node contains an implicit array.
isArray = (elementNode) ->
  inspect.hasMultipleValues elementNode


# Helps to identify whether given *Element* node contains an implicit object.
#
# There are two ways how to say whether there are "nested member types".
# First way is to count individual member types one by one, second way is
# to count whether there are "containers" for these nested types.
#
# The second approach makes more sense, because counting individual
# nested objects would cause problems with empty "containers", which
# are probably sufficient proof of nested members, but contain zero of them.
#
# However, this 'race condition' probably can't happen anyway, so these
# approaches shouldn't(tm) make a difference.
isObject = (elementNode) ->
  inspect.hasAnyMemberSections elementNode


# Resolves array of implicit nested types for given *Element* node containing
# *Property Member* or *Value Member*.
resolveImplicitNestedTypes = (typeName, elementNode, cb) ->
  if typeName in ['array', 'enum'] and (inspect.listValues elementNode).length
    cb null, ['string']
  else
    cb null, []


# Resolves implicit 'simple type specification object'
#
#     name: ...
#     nested: [...]
#
# for given *Element* node containing *Property Member* or *Value Member*.
resolveImplicitType = (elementNode, cb) ->
  isArr = isArray elementNode
  isObj = isObject elementNode

  if isObj and isArr
    # just playing safe, this should be already ensured by MSON parser
    cb new Error "Unable to resolve type. Ambiguous implicit type (seems to be both object and inline array)."
  else
    name = ('array' if isArr) or ('object' if isObj) or 'string'

    resolveImplicitNestedTypes name, elementNode, (err, nested) ->
      cb err, ({name, nested} unless err)


# Resolves inherited type.
#
# This can happen only to primitive types, so we don't care about 'nested'
# and also, in this particular case we're not 'playing safe' by raising
# errors in case there's type mismatch or in case we've got some nonsense
# instead of 'typeName'. For simplicity of code here we just take what's
# inherited (with higher priority).
resolveInheritedType = (elementNode, inheritedTypeName, cb) ->
  cb null, {name: inheritedTypeName, nested: []}


# Ensures implicit nested types are added to given
# 'simple type specification object' in case such option is applicable.
ensureImplicitNestedTypes = (elementNode, simpleTypeSpec, cb) ->
  if simpleTypeSpec.nested?.length
    # we already got some nested types
    cb null, simpleTypeSpec
  else
    # no nested types, so we check whether it's not a situation where we can
    # resolve implicit nested types - in that case we add them to the
    # *simpleTypeSpec* object
    name = simpleTypeSpec.name
    resolveImplicitNestedTypes name, elementNode, (err, nested) ->
      cb err, ({name, nested} unless err)


# Takes *Element* tree node containing *Property Member* or *Value Member*.
# The *inheritedTypeName* argument is optional.
#
# Provides a sort of 'simple type specification object':
#
#     name: ...
#     nested: [...]
#
# In case it isn't able to resolve this *typeSpecification* object with
# base types only, ends with an error (Boutique builds no symbol table,
# so it can't resolve any possible inheritance).
resolveType = (elementNode, inheritedTypeName, cb) ->
  # process arguments
  if inheritedTypeName
    if typeof inheritedTypeName is 'function'
      cb = inheritedTypeName
    else
      # we've got inherited type
      return resolveInheritedType elementNode, inheritedTypeName, cb

  # no inherited type, let's start regular type resolution
  typeSpec = inspect.findTypeSpecification elementNode
  simplifyTypeSpecification typeSpec, (err, simpleTypeSpec) ->
    return cb err if err
    return resolveImplicitType elementNode, cb unless simpleTypeSpec
    ensureImplicitNestedTypes elementNode, simpleTypeSpec, cb


resolveTypes = (elementNodes, inheritedTypeName, cb) ->
  async.map elementNodes, (elementNode, next) ->
    resolveType elementNode, inheritedTypeName, next
  , cb


module.exports = {
  resolveType
  resolveTypes
}
