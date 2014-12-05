
async = require 'async'

serializers = require './lib/serializers'
{selectFormat} = require './lib/formatselection'


formats =
  'application/schema+json':
    lib: require './lib/formats/jsonschema-v4'
    serialize: serializers.json


represent = ({ast, contentType, options}, cb) ->
  ast ?= {}
  contentType ?= 'application/schema+json'
  options ?= {}

  selectedContentType = selectFormat contentType, Object.keys formats
  if selectedContentType
    {lib, serialize} = formats[selectedContentType]

    async.waterfall [
        (next) ->
          lib.transform ast, options, next
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
