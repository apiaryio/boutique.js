
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

  nested = (typeName.name for typeName in typeSpec.nestedTypes)
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


# Helps to identify whether given node is an implicit array.
isArray = (node) ->
  (node.valueDefinition?.values?.length or 0) > 1  # has multiple values?


# Helps to identify whether given node is an implicit object.
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
isObject = (node) ->
  (s for s in (node.sections or []) when s.type is 'member').length  # has any member sections?


# TODO: should be tested
#
# Resolves array of implicit nested types for given *Named Type*
# or *Property Member* or *Value Member* tree node.
resolveImplicitNestedTypes = (typeName, node, cb) ->
  if typeName is 'array' and (inspect.listValues node).length
    cb null, ['string']
  else
    cb null, []


# Resolves implicit 'simple type specification object'
#
#     name: ...
#     nested: [...]
#
# for given *Named Type* or *Property Member* or *Value Member* tree node.
resolveImplicitType = (node, cb) ->
  isArr = isArray node
  isObj = isObject node

  if isObj and isArr
    # just playing safe, this should be already ensured by MSON parser
    cb new Error "Unable to resolve type. Ambiguous implicit type (seems to be both object and inline array)."
  else
    name = ('array' if isArr) or ('object' if isObj) or 'string'

    resolveImplicitNestedTypes name, node, (err, nested) ->
      cb err, ({name, nested} unless err)


# TODO: should be tested
resolveInheritedType = (node, inheritedTypeName, cb) ->
  # This can happen only to primitive types, so we don't care about 'nested'
  # and also, in this particular case we're not 'playing safe' by raising
  # errors in case there's type mismatch or in case we've got some nonsense
  # instead of 'typeName'. For simplicity of code here we just take what's
  # inherited (with higher priority).
  cb null, {name: inheritedTypeName, nested: []}


# Takes top-level *Named Type* or *Property Member* or *Value Member* tree node.
# Provides a sort of 'simple type specification object':
#
#     name: ...
#     nested: [...]
#
# In case it isn't able to resolve this *typeSpecification* object with
# base types only, ends with an error (Boutique builds no symbol table,
# so it can't resolve any possible inheritance).
resolveType = (node, inheritedTypeName, cb) ->
  if inheritedTypeName
    if typeof inheritedTypeName is 'function'
      cb = inheritedTypeName
    else
      return resolveInheritedType node, inheritedTypeName, cb

  typeSpec = inspect.findTypeSpecification node
  simplifyTypeSpecification typeSpec, (err, simpleTypeSpec) ->
    return cb err if err
    return resolveImplicitType node, cb unless simpleTypeSpec

    if simpleTypeSpec.nested?.length
      cb null, simpleTypeSpec
    else
      name = simpleTypeSpec.name
      resolveImplicitNestedTypes name, node, (err, nested) ->
        cb err, ({name, nested} unless err)


module.exports = {
  resolveType
}
