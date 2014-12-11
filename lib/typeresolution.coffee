
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

    # just playing safe, this should be already checked by MSON parser
    if type not in ['array', 'enum']
      return cb new Error "Nested types are allowed only for array and enum types."

    nested = (typeName.name for typeName in typeSpecification.nestedTypes)
    async.map nested, ensurePrimitiveType, (err) ->
      return cb err if err  # again, non-primitive types result in error
      cb null, {name: type, nested}


# There are two ways how to say whether there are "nested member types".
# First way is to count individual member types one by one, second way is
# to count whether there are "containers" for these nested types.
#
# The second approach makes more sense, because counting individual
# nested objects would cause problems with empty "containers", which
# are probably sufficient proof of nested members, but contain zero of them.
containsNestedMemberTypes = (node) ->
  sections = node.sections or []
  memberSections = sections.filter (section) ->
    section.type is 'member'
  memberSections.length > 0


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
  typeSpecification = null
  implicitType = if containsNestedMemberTypes node then 'object' else 'string'

  if node?.base?.typeSpecification?
    # We got top-level *Named Type* node.
    typeSpecification = node?.base?.typeSpecification
  else
    # *Property Member* or *Value Member* node
    typeSpecification = node?.valueDefinition?.typeDefinition?.typeSpecification

  simplifyTypeSpecification typeSpecification, (err, spec) ->
    return cb err if err
    cb null, spec or {name: implicitType}


module.exports = {
  resolveType
}
