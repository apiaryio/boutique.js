
async = require 'async'


# Listing of all primitive types as defined in MSON AST spec.
primitiveTypes = ['boolean', 'string', 'number', 'array', 'enum', 'object']


# Checks whether given type name is one of primitive types.
isPrimitiveType = (type) ->
  type in primitiveBaseTypes


# Calls given function with an error in case given type name is not one
# of primitive types.
ensurePrimitiveType = (type, cb) ->
  if not isPrimitiveType type
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

    spec = name: type
    return cb null, spec if typeSpecification.nestedTypes.length < 1  # no nested types

    # just playing safe, following shouldn't happen
    if spec.name not in ['array', 'enum']
      return cb new Error "Nested types are allowed only for array and enum types."

    nested = [typeName.name for typeName in typeSpecification.nestedTypes]
    async.map nested, ensurePrimitiveType, (err) ->
      return cb err if err  # again, non-primitive types result in error

      spec.nested = nested
      cb null, spec


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
  implicitType = null

  if node?.base?.typeSpecification?
    # We got top-level *Named Type* node.
    typeSpecification = node?.base?.typeSpecification
    implicitType = 'object'

  else
    # *Property Member* or *Value Member* node
    typeSpecification = node?.valueDefinition?.typeDefinition?.typeSpecification

    # Figure out the implicit type of this node
    if node?.valueDefinition?.values?.length > 0
      implicitType = 'array'
    else
      # does it have any sub members?
      memberSectionsCount = 0
      for section in node?.sections or []
        memberSectionsCount += 1 if section.type is 'member'
      implicitType = if memberSectionsCount > 0 then 'object' else 'string'

  simplifyTypeSpecification node, (err, spec) ->
    return cb err if err
    return cb null, spec or name: implicitType


module.exports = {
  resolveType
}
