require 'mocha'
fs = require 'fs'
path = require 'path'
{assert} = require 'chai'

boutique = require '../index'


describe "Main ‘represent(...)’ function", ->

  describe "when given sample AST from MSON AST documentation", ->
    astFile = path.resolve __dirname, 'index-test-ast.json'
    schemaFile = path.resolve __dirname, 'index-test-schema.json'

    ast = undefined
    schema = undefined
    contentType = undefined

    before (next) ->
      fs.readFile astFile, 'utf8', (err, data) ->
        if err then return next err

        boutique.represent
          ast: JSON.parse(data)
        , ->
          [err, schema, contentType] = arguments
          next err

    it "representation is string", ->
      assert.equal 'string', typeof schema

    it "resulting content type is ‘application/schema+json’", ->
      assert.equal 'application/schema+json', contentType

    it "AST is represented correctly", (next) ->
      fs.readFile schemaFile, 'utf8', (err, data) ->
        if err then return next err
        assert.deepEqual JSON.parse(data), JSON.parse(schema)
        next()
