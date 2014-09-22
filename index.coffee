
async = require 'async'

{Boutique} = require './lib/boutique'
{serializers} = require './lib/serializers'
{selectFormat} = require './lib/formatselection'


formats =
  'application/json':
    lib: require './lib/formats/json'
    serialize: serializers.json


represent = (ast, contentType, options, cb) ->
  if typeof options is 'function' then cb = options
  key = selectFormat contentType, Object.keys formats

  if key
    {lib, serialize} = formats[key]

    async.waterfall [
        (next) ->
          format = new lib.Format options
          boutique = new Boutique format
          boutique.represent ast, impl, next
      ,
        (obj, next) ->
          serialize obj, next

    ], cb
  else
    cb new Error "Content-Type '#{contentType}' is not implemented."


module.exports = {
  represent
}
