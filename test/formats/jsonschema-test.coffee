require 'mocha'

{createTest} = require '../testutils'
format = require '../../lib/formats/jsonschema'


describe "JSON Schema format", ->
  test = createTest format
