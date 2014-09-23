require 'mocha'

{createDescribe} = require '../testutils'
{Format} = require '../../lib/formats/json'


describe "JSON format", ->
  boutique = createDescribe new Format

  boutique "handles basic MSON AST",
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
    repr:
      id: 1
    reprDesc: 'object with one property of name ‘id’, having number ‘1’ as a value'

  boutique "properly handles ‘string’",
    ast:
      primitive:
        type: 'string'
        value: 'Dummy value'
    repr: 'Dummy value'
    reprDesc: 'string with value ‘Dummy value’'

  boutique "properly handles tricky ‘string’",
    ast:
      primitive:
        type: 'string'
        value: 'Žvýkačka: \' ≤ "'
    repr: 'Žvýkačka: \' ≤ "'
    reprDesc: 'string with value ‘Žvýkačka: \' ≤ \\"’'

  boutique "properly handles ‘number’",
    ast:
      primitive:
        type: 'number'
        value: '1.2'
    repr: 1.2
    reprDesc: 'number with value ‘1.2’'

  boutique "properly handles ‘bool’",
    ast:
      primitive:
        type: 'bool'
        value: 'true'
    repr: true
    reprDesc: 'boolean with value ‘true’'

  boutique "properly handles ‘array’",
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
    repr: ['h2g2', 42]
    reprDesc: 'array containing two elements: string with value ‘h2g2’ and number with value ‘42’'

  boutique "properly handles ‘object’",
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
    repr:
      abbr: 'h2g2'
      id: 42
    reprDesc: 'object containing two properties: string ‘abbr’ with value ‘h2g2’ and number ‘id’ with value ‘42’'
