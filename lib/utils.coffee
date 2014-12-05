
traverse = require 'traverse'


###########################################################################
## PROTOTYPE ALERT! This is work in progress as much as it only can be.  ##
###########################################################################


# Provides the type to be rendered and "symbol table" for named types.
selectType = (ast, typeName, cb) ->
  typesArray = ast?.types or []

  symbolTable = {}
  for type in typesArray
    symbolTable[type.name?.name?.literal] = type

  if typesArray.length < 1
    # "Empty" or corrupted AST given. Go on with empty Named Type object.
    # Boutique should generate "empty" representation on such input, which
    # is specific for each content type. (This is subject to change - passing
    # null/undefined might actually work better, depends on format
    # implementations...)
    selectedType = {}
  else if not typeName
    # Type was NOT explicitely selected. We go with the first one.
    selectedType = typesArray[0]
  else
    # Type was explicitely selected.
    selectedType = types[typeName]

  cb null, selectedType, symbolTable


module.exports = {
  selectType
}
