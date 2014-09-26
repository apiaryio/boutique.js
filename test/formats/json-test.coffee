require 'mocha'

{createDescribe} = require '../testutils'
{Format} = require '../../lib/formats/json'


describe "JSON format", ->
  boutique = createDescribe Format

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

  boutique "handles empty MSON AST given as empty object",
    ast: {}
    repr: null
    reprDesc: 'empty representation'

  boutique "handles empty MSON AST given as ‘null’",
    ast: null
    repr: null
    reprDesc: 'empty representation'

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

  boutique "properly handles ‘boolean’",
    ast:
      primitive:
        type: 'boolean'
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

  boutique "generates optional properties by default",
    ast:
      primitive:
        type: 'object'
        value: [
            name: 'id'
            required: true
            description: 'The unique identifier of an employee'
            primitive:
              type: 'number'
              value: '1'
          ,
            name: 'name'
            required: false
            description: 'Name of the employee'
            primitive:
              type: 'string'
              value: 'Věroš'
        ]
    repr:
      id: 1
      name: 'Věroš'
    reprDesc: 'object with one required property of name ‘id’ and one optional property of name ‘name’'

  boutique "doesn't generate optional properties if ‘skipOptional’ option given as ‘true’",
    options:
      skipOptional: true
    ast:
      primitive:
        type: 'object'
        value: [
            name: 'id'
            required: true
            description: 'The unique identifier of an employee'
            primitive:
              type: 'number'
              value: '1'
          ,
            name: 'name'
            required: false
            description: 'Name of the employee'
            primitive:
              type: 'string'
              value: 'Věroš'
        ]
    repr:
      id: 1
    reprDesc: 'object with one required property of name ‘id’'

  boutique "doesn't generate templated properties",
    ast:
      primitive:
        type: 'object'
        value: [
            name: 'id'
            required: true
            description: 'The unique identifier of an employee'
            primitive:
              type: 'number'
              value: '1'
          ,
            name: 'additional properties'
            templated: true
            description: 'Any other additional properties.'
        ]
    repr:
      id: 1
    reprDesc: 'object with one required property of name ‘id’'

  boutique "selects the first element from ‘oneOf’",
    ast:
      primitive:
        type: 'array'
        value: [
            primitive:
              type: 'number'
              value: '1'
          ,
            oneOf: [
              primitive:
                type: 'number'
                value: '42'
            ,
              primitive:
                type: 'string'
                value: 'hello'
          ]
        ]
    repr: [
      1, 42
    ]
    reprDesc: 'array with numbers ‘1’ and ‘42’'

  boutique "selects the first property from ‘oneOf’",
    ast:
      primitive:
        value: [
            name: 'name'
            primitive:
              value: 'Věroš'
          ,
            oneOf: [
                name: 'xor1'
                primitive:
                  type: 'number'
                  value: '42'
              ,
                name: 'xor2'
                primitive:
                  type: 'string'
                  value: 'hello'
            ]
          ,
            name: 'size'
            primitive:
              value: 'XL'
        ]
    repr:
      name: 'Věroš'
      xor1: 42
      size: 'XL'
    reprDesc: 'object with properties ‘name’, ‘xor1’, and ‘size’.'
