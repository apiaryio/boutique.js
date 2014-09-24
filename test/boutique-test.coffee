require 'mocha'
fs = require 'fs'
path = require 'path'

{createDescribe} = require './testutils'


FORMATS_DIR = '../lib/formats'

for file in fs.readdirSync path.join __dirname, FORMATS_DIR when file isnt 'base.coffee'
  formatPath = path.join FORMATS_DIR, file
  {Format} = require formatPath


  # Core Boutique tests. Should test features of Boutique itself,
  # traversal algorithms, etc. Tested with every available format.

  describe "Core Boutique (tested with ‘#{path.basename file, '.coffee'}’)", ->
    boutique = createDescribe Format

    boutique "handles empty MSON AST given as empty object",
      ast: {}
      repr: null
      reprDesc: 'empty representation'

    boutique "handles empty MSON AST given as ‘null’",
      ast: null
      repr: null
      reprDesc: 'empty representation'

    boutique "ensures that ‘primitive’ and ‘oneOf’ are mutually exclusive",
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
      errDesc: 'mutually exclusive'

    boutique "ensures that ‘primitive’ and ‘ref’ are mutually exclusive",
      ast:
        primitive:
          type: 'string'
          value: 'Dummy value'
        ref: 'Something'
      errDesc: 'mutually exclusive'

    boutique "ensures that ‘ref’ and ‘oneOf’ are mutually exclusive",
      ast:
        oneOf: [
            primitive:
              type: 'number'
              value: '0'
          ,
            primitive:
              type: 'number'
              value: '1'
        ]
        ref: 'Something'
      errDesc: 'mutually exclusive'

    boutique "properly handles an element without neither type or example value",
      ast:
        description: 'Dummy description'
      repr: null
      reprDesc: 'empty value'

    boutique "properly handles simple value without type as ‘string’",
      ast:
        primitive:
          value: '123'
      repr: '123'
      reprDesc: 'string with value ‘123’'

    boutique "properly handles complex value without type as ‘object’",
      ast:
        primitive:
          value: [
            name: 'name'
            primitive:
              value: 'Gargamel'
          ]
      repr:
        name: 'Gargamel'
      reprDesc: 'object with one property of name ‘name’, having string ‘Gargamel’ as a value'

    boutique "properly handles an element with type, but without value",
      ast:
        primitive:
          type: 'number'
      repr: null
      reprDesc: 'empty value'

    boutique "doesn't implement ‘ref’ yet",
      ast:
        ref: 'Another'
      errDesc: 'implemented'
