require 'mocha'
fs = require 'fs'
path = require 'path'
{assert} = require 'chai'

boutique = require '../index'


# TODO
# Currently, following test takes file with AST sample, runs Boutique and checks
# whether the output is the same as in file with output sample (e.g. JSON Schema).
#
# In future, this should change - the test should take plain text files with MSON,
# parse them on-the-fly into ASTs and then run Boutique with them. The directory
# with AST samples should not be present in the future. Directory with MSON files
# is prepared, but not used for anything useful now - it's there just as a roadmap
# and for the future version of this test suite.


astSamplesDir = 'samples-ast'
astSamplesExt = 'json'

formatSamples = [
    dir: 'samples-json-schema-v4'
    ext: 'json'
    contentType: 'application/schema+json'
    parse: (str) -> JSON.parse str

  # TODO (once there's JSON representer...)
  #
  #,
  #  directory: 'json'
  #  extension: 'json'
  #  contentType: 'application/json'
  #  parse: (str) -> JSON.parse str
]


samples = {
  'complex-object': "complex object (example from MSON AST spec README file)"
  'simple-object': "simple object"
  # ... more tests
}


describe "Main ‘represent(...)’ function", ->

  for name, description of samples
    astFileBasename = "#{name}.#{astSamplesExt}"
    describe "with sample AST for #{description} (file ‘#{astFileBasename}’)", ->

      for {dir, ext, contentType, parse} in formatSamples
        describe "generates representation in ‘#{contentType}’", ->

          reprFileBasename = "#{name}.#{ext}"
          astFile = path.resolve __dirname, astSamplesDir, astFileBasename
          reprFile = path.resolve __dirname, dir, reprFileBasename

          ast = undefined
          repr = undefined

          before (next) ->
            fs.readFile astFile, 'utf8', (err, data) ->
              if err then return next err

              boutique.represent
                ast: parse data
              , ->
                [err, repr] = arguments
                next err

          it "correctly, as in ‘#{reprFileBasename}’", (next) ->
            fs.readFile reprFile, 'utf8', (err, data) ->
              if err then return next err
              assert.deepEqual parse(data), parse(repr)
              next()
