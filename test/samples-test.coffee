require 'mocha'
fs = require 'fs'
path = require 'path'
{assert} = require 'chai'

boutique = require '../index'


astSamplesDir = 'samples-ast'

formatSamplesDirs = {
  'samples-json-schema-v4': 'application/schema+json'
}

samples = {
  'readme-sample.json': "example from MSON spec README file"
}


describe "Main ‘represent(...)’ function", ->

  for file, name of samples
    describe "when given sample AST for ‘#{name}’ (file ‘#{file}’)", ->

      for directory, contentType of formatSamplesDirs
        describe "and trying to get it's representation in ‘#{contentType}’", ->

          astFile = path.resolve __dirname, astSamplesDir, file
          schemaFile = path.resolve __dirname, directory, file

          ast = undefined
          schema = undefined

          before (next) ->
            fs.readFile astFile, 'utf8', (err, data) ->
              if err then return next err

              boutique.represent
                ast: JSON.parse data
              , ->
                [err, schema] = arguments
                next err

          it "AST is represented correctly", (next) ->
            fs.readFile schemaFile, 'utf8', (err, data) ->
              if err then return next err
              assert.deepEqual JSON.parse(data), JSON.parse(schema)
              next()
