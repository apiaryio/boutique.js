
async = require 'async'

{Boutique} = require './lib/boutique'
serializers = require './lib/serializers'
{parseArguments} = require './lib/arguments'
{selectFormat} = require './lib/formatselection'


formats =
  'application/json':
    lib: require './lib/formats/json'
    serialize: serializers.json


# Possible signatures:
#
# represent(ast, contentType, cb)
# represent(ast, contentType, options, cb)
# represent(ast, contentType, typeIdentifier, cb)
# represent(ast, contentType, typeIdentifier, options, cb)
represent = ->
  {ast, contentType, typeIdentifier, options, cb} = parseArguments arguments

  selectedContentType = selectFormat contentType, Object.keys formats
  if selectedContentType
    {lib, serialize} = formats[selectedContentType]

    async.waterfall [
        (next) ->
          format = new lib.Format options
          boutique = new Boutique format
          boutique.represent ast, typeIdentifier, next
      ,
        (obj, next) ->
          serialize obj, next

    ], (err, repr) ->
      cb err, repr, selectedContentType
  else
    cb new Error "Content-Type '#{contentType}' is not implemented."


module.exports = {
  represent
}
