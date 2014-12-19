
fs = require 'fs'
path = require 'path'
async = require 'async'

try
  tv4 = require 'tv4'
catch
  console.error "You need to install the tv4 first by running 'npm install tv4'."
  process.exit 1


metaSchemaPath = path.resolve __dirname, 'metaschemas', 'json-schema-v4.json'
formatsDir = path.resolve __dirname, '..', 'test', 'formats'
schemaDirs = [
  path.resolve formatsDir, 'samples-json-schema-v4'
]


# Reads a file with JSON Schema and provides it's contents
# as a JavaScript object.
readSchemaFile = (schemaPath, cb) ->
  fs.readFile schemaPath, (err, data) ->
    return cb err if err
    try
      schema = JSON.parse data.toString()
      cb null, schema
    catch err
      cb new Error "#{schemaPath}: #{err.message}"


# Checks whether given JavaScript object represents
# a valid JSON Schema schema according to given meta schema.
checkSchema = (schema, metaSchema, cb) ->
  result = tv4.validateResult schema, metaSchema
  if result.missing?.length
    cb new Error "Missing schemas: #{result.missing}"
  if not result.valid
    cb result.error
  else
    cb()


# Checks whether a file on given path contains JSON representing
# a valid JSON Schema schema according to given meta schema.
checkSchemaFile = (schemaPath, metaSchema, cb) ->
  async.waterfall [
    (next) -> readSchemaFile schemaPath, next
    (schema, next) -> checkSchema schema, metaSchema, (err) ->
      next (new Error "#{schemaPath}: #{err.message}" if err)
  ], cb


# Checks whether all `.json` files in given directory contain
# JSONs representing valid JSON Schema schemas according to given meta schema.
checkSchemaDir = (schemaDir, metaSchema, cb) ->
  fs.readdir schemaDir, (err, filenames) ->
    jsonFilenames = (f for f in filenames when f.match /\.json$/)
    async.forEach jsonFilenames, (filename, next) ->
      schemaPath = path.resolve schemaDir, filename
      checkSchemaFile schemaPath, metaSchema, next
    , cb


# Checks whether all `.json` files in predefined directories contain
# JSONs representing valid JSON Schema schemas according to given meta schema.
checkSchemaDirs = (metaSchema, cb) ->
  tv4.addSchema '', metaSchema
  tv4.addSchema metaSchema.$schema, metaSchema if metaSchema.$schema

  async.forEach schemaDirs, (schemaDir, next) ->
    checkSchemaDir schemaDir, metaSchema, next
  , cb


main = ->
  async.waterfall [
    (next) -> readSchemaFile metaSchemaPath, next
    checkSchemaDirs
  ], (err) ->
    if err
      console.error "[JSON Schema Lint] #{err.message}", err
      process.exit 1


main()
