require 'mocha'
{assert} = require 'chai'

{Boutique} = require '../../lib/boutique.coffee'
format = require '../../lib/formats/json.coffee'


describe "JSON format", ->
  test = ({ast, repr, reprDesc, errDesc, options}) ->
    ->
      boutique = new Boutique format, options

      e = undefined
      r = undefined

      before (next) ->
        boutique.represent ast, ->
          [e, r] = arguments
          next()

      if errDesc
        it "fails on error, which contains words ‘#{errDesc}’", ->
          assert.ok e
          assert.include e.message, errDesc
      else
        desc = "produces " + (reprDesc or "the right representation")
        it desc, ->
          assert.equal r, repr

  describe "handles basic MSON AST", test
    ast:
      primitive:
        type: 'object'
        value: [
          name: 'id'
          required: true
          description: 'The unique identifier for a product'
          primitive:
            type: 'number'
            value: '1'
        ]
    repr: '{"id":1}'
    reprDesc: 'object with one property of name ‘id’, having number ‘1’ as a value'

  describe "properly handles ‘string’", test
    ast:
      primitive:
        type: 'string'
        value: 'Dummy value'
    repr: '"Dummy value"'
    reprDesc: 'string with value ‘Dummy value’'

  describe "properly handles tricky ‘string’", test
    ast:
      primitive:
        type: 'string'
        value: 'Žvýkačka: \' ≤ "'
    repr: '"Žvýkačka: \' ≤ \\""'
    reprDesc: 'string with value ‘Žvýkačka: \' ≤ \\"’'

  describe "properly handles ‘number’", test
    ast:
      primitive:
        type: 'number'
        value: '1.2'
    repr: '1.2'
    reprDesc: 'number with value ‘1.2’'

  describe "properly handles ‘bool’", test
    ast:
      primitive:
        type: 'bool'
        value: 'true'
    repr: 'true'
    reprDesc: 'boolean with value ‘true’'

  describe "properly handles ‘array’", test
    ast:
      primitive:
        type: 'array'
        value: [
            primitive:
              type: 'string'
              value: 'h2g2'
          ,
            primitive:
              type: 'number'
              value: '42'
        ]
    repr: '["h2g2",42]'
    reprDesc: 'array containing two elements: string with value ‘h2g2’ and number with value ‘42’'

  describe "properly handles ‘object’", test
    ast:
      primitive:
        type: 'object'
        value: [
            name: 'abbr'
            primitive:
              type: 'string'
              value: 'h2g2'
          ,
            name: 'id'
            primitive:
              type: 'number'
              value: '42'
        ]
    repr: '{"abbr":"h2g2","id":42}'
    reprDesc: 'object containing two properties: string ‘abbr’ with value ‘h2g2’ and number ‘id’ with value ‘42’'
