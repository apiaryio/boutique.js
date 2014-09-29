
async = require 'async'

{Boutique} = require './lib/boutique'
serializers = require './lib/serializers'
{selectFormat} = require './lib/formatselection'


formats =
  'application/json':
    lib: require './lib/formats/json'
    serialize: serializers.json


represent = (ast, contentType, options, cb) ->
  if typeof options is 'function' then cb = options
  selectedContentType = selectFormat contentType, Object.keys formats

  if selectedContentType
    {lib, serialize} = formats[selectedContentType]

    async.waterfall [
        (next) ->
          format = new lib.Format options
          boutique = new Boutique format
          boutique.represent ast, next
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
