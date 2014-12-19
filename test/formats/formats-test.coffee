require 'mocha'
fs = require 'fs'
path = require 'path'
{assert} = require 'chai'

boutique = require '../../index'


readAstSample = (sampleName, cb) ->
  filename = path.resolve __dirname, 'samples-ast', "#{sampleName}.json"
  fs.readFile filename, 'utf8', (err, data) ->
    cb err, (JSON.parse data unless err)


testFormat = ({name, contentType, dir, ext, parse, samples}) ->
  # generate single top-level 'describe' block for given format
  describe "#{name} format", ->
    for sample in samples
      # generate 'describe' block for each specified sample
      describe "given ‘#{sample}’ sample", ->
        sampleName = sample  # without this the variable isn't properly scoped for `before` (grr..)
        repr = null
        reprSample = null

        before (next) ->
          # 1. read representation sample
          filename = path.resolve __dirname, dir, "#{sampleName}.#{ext}"
          fs.readFile filename, 'utf8', (err, data) ->
            return next err if err
            reprSample = parse data

            # 2. read AST sample
            readAstSample sampleName, (err, ast) ->
              return next err if err

              # 3. run Boutique with the AST and save the output
              boutique.represent {ast, contentType}, (err, data) ->
                repr = parse data if not err
                next err

        it "generates expected representation", ->
          # 4. check whether the output from Boutique equals the repr. sample
          assert.deepEqual reprSample, repr


testFormat
  name: 'JSON Schema v4'
  contentType: 'application/schema+json'
  dir: 'samples-json-schema-v4'
  ext: 'json'
  parse: JSON.parse
  samples: [
    'array'
    # 'array-of-arrays'
    # 'array-with-type'
    'boolean'
    'complex-object'
    # 'description'
    # 'enum-containing-enum'
    # 'enum-containing-object'
    # 'enum-containing-sample'
    # 'enum-of-strings'
    # 'enum-with-type'
    # 'escaping'
    'inline-array'
    # 'mixed-array-complex'
    # 'mixed-array'
    'number'
    'optional'
    'required'
    'simple-object'
    'string'
    # 'variable-property'
    # 'very-complex-object'
  ]


testFormat
  name: 'JSON'
  contentType: 'application/json'
  dir: 'samples-json'
  ext: 'json'
  parse: JSON.parse
  samples: []
