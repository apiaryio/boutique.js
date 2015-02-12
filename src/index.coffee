
async = require 'async'

serializers = require './serializers'
{selectFormat} = require './formatselection'


jsonSchemaV4 =
  lib: require './formats/jsonschema-v4'
  serialize: serializers.json

json =
  lib: require './formats/json'
  serialize: serializers.json

formats =
  'application/schema+json': jsonSchemaV4
  'application/schema+json; profile="http://json-schema.org/schema"': jsonSchemaV4
  'application/schema+json; profile="http://json-schema.org/draft-04/schema"': jsonSchemaV4
  'application/json': json


represent = ({ast, contentType}, cb) ->
  ast ?= {}
  contentType ?= 'application/schema+json'
  availableContentTypes = Object.keys formats

  selectFormat contentType, availableContentTypes, (err, selectedContentType) ->
    return cb err if err
    return cb new Error "Content-Type '#{contentType}' is not implemented." unless selectedContentType

    {lib, serialize} = formats[selectedContentType]

    async.waterfall [
        (next) ->
          lib.transform ast, next
      ,
        (obj, next) ->
          serialize obj, next

    ], (err, repr) ->
      cb err, repr, selectedContentType


module.exports = {
  represent
}
