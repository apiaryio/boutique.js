
async = require 'async'


# Listing of all primitive types as defined in MSON AST spec.
primitiveTypes = ['boolean', 'string', 'number', 'array', 'enum', 'object']


# Calls given function with an error in case given type name is not one
# of primitive types.
ensurePrimitiveType = (type, cb) ->
  if type not in primitiveTypes
    cb new Error "Unable to resolve type: #{type}"
  else
    cb null


# Turns *typeSpecification* object as described in
# https://github.com/apiaryio/mson-ast#type-definition into something simpler:
#
#     name: ...
#     nested: [...]
#
# In case it isn't able to resolve this *typeSpecification* object with
# primitive types only, ends with an error (Boutique builds no symbol table,
# so it can't resolve any possible inheritance).
simplifyTypeSpecification = (typeSpecification, cb) ->
  type = typeSpecification?.name?.name
  return cb null, null if not type  # no type? return null...

  ensurePrimitiveType type, (err) ->
    return cb err if err  # non-primitive type results in error
    return cb null, {name: type} if (typeSpecification?.nestedTypes?.length or 0) < 1  # no nested types

    # just playing safe, this should be already ensured by MSON parser
    if type not in ['array', 'enum']
      return cb new Error "Nested types are allowed only for array and enum types."

    nested = (typeName.name for typeName in typeSpecification.nestedTypes)
    async.map nested, ensurePrimitiveType, (err) ->
      return cb err if err  # again, non-primitive types result in error
      cb null, {name: type, nested}


# Helps to identify whether given node is an implicit array.
hasMultipleValues = (node) ->
  !!node.valueDefinition?.values?.length


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
containsNestedMemberTypes = (node) ->
  sections = node.sections or []
  memberSections = sections.filter (section) ->
    section.type is 'member'
  memberSections.length > 0


# Resolves implicit type for given *Named Type* or *Property Member*
# or *Value Member* tree node.
resolveImplicitType = (node, cb) ->
  isArray = hasMultipleValues node
  isObject = containsNestedMemberTypes node

  if isObject and isArray
    # just playing safe, this should be already ensured by MSON parser
    cb new Error "Unable to resolve type. Ambiguous implicit type (seems to be both object and inline array)."
  else
    type = ('array' if isArray) or ('object' if isObject) or 'string'
    cb null, type


# Finds *typeSpecification* object for given *Named Type* or *Property Member*
# or *Value Member* tree node.
findTypeSpecification = (node) ->
  if node.base?.typeSpecification?
    # Top-level *Named Type* node.
    node.base.typeSpecification
  else
    # *Property Member* or *Value Member* node
    node.valueDefinition?.typeDefinition?.typeSpecification


# Takes top-level *Named Type* or *Property Member* or *Value Member* tree node.
# Provides a sort of 'simple type specification object':
#
#     name: ...
#     nested: [...]
#
# In case it isn't able to resolve this *typeSpecification* object with
# primitive types only, ends with an error (Boutique builds no symbol table,
# so it can't resolve any possible inheritance).
resolveType = (node, cb) ->
  typeSpecification = findTypeSpecification node
  simplifyTypeSpecification typeSpecification, (err, spec) ->
    if err
      cb err
    else if not spec
      resolveImplicitType node, (err, implicitType) ->
        cb err, name: implicitType
    else
      cb null, spec


module.exports = {
  resolveType
}
