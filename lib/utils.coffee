
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
    selectedType = {}
  else if not typeName
    selectedType = typesArray[0]
  else
    selectedType = types[typeName]

  cb null, selectedType, symbolTable


module.exports = {
  selectType
}
